/* Functional PLR baseline validation; upstream routing code is unchanged. */
#include "ns3/core-module.h"
#include "ns3/network-module.h"
#include "ns3/internet-module.h"
#include "ns3/mobility-module.h"
#include "ns3/wifi-module.h"
#include "ns3/wave-module.h"
#include "ns3/aodv-module.h"
#include "ns3/applications-module.h"
#include <fstream>
#include <iostream>
#include <set>
#include <string>

using namespace ns3;

namespace {
const uint16_t PORT = 9000;
const uint32_t TEST_PACKET_COUNT = 12;
const Ipv4Address SOURCE ("10.2.0.1");
const Ipv4Address DESTINATION ("10.2.0.3");
uint32_t sourceTx = 0;
uint32_t relayForward = 0;
uint32_t sourceRreq = 0;
std::set<uint32_t> forwardedSequences;
std::ofstream forwardingTrace;

bool IsTestData (const Ipv4Header &ip, Ptr<const Packet> packet)
{
  if (ip.GetProtocol () != 17 || ip.GetSource () != SOURCE ||
      ip.GetDestination () != DESTINATION || packet->GetSize () < 8)
    {
      return false;
    }
  UdpHeader udp;
  packet->PeekHeader (udp);
  return udp.GetDestinationPort () == PORT;
}

void SourceTx (Ptr<const Packet> packet, Ptr<Ipv4>, uint32_t interface)
{
  // The low-level Tx trace includes the IPv4 header. Exclude fake loopback
  // transmissions while AODV queues a packet waiting for route discovery.
  if (interface == 0)
    {
      return;
    }
  Ptr<Packet> copy = packet->Copy ();
  Ipv4Header ip;
  copy->RemoveHeader (ip);
  if (IsTestData (ip, copy))
    {
      ++sourceTx;
    }
}

void RelayForward (const Ipv4Header &ip, Ptr<const Packet> packet, uint32_t)
{
  // Unlike Tx, the UnicastForward trace passes the IPv4 header separately.
  if (!IsTestData (ip, packet))
    {
      return;
    }
  Ptr<Packet> copy = packet->Copy ();
  UdpHeader udp;
  SeqTsHeader sequence;
  copy->RemoveHeader (udp);
  copy->PeekHeader (sequence);
  ++relayForward;
  forwardedSequences.insert (sequence.GetSeq ());
  forwardingTrace << Simulator::Now ().GetSeconds () << ','
                  << sequence.GetSeq () << ",1," << uint32_t (ip.GetTtl ()) << '\n';
}

void RoutingTx (Ptr<const Packet> packet)
{
  aodv::TypeHeader type;
  packet->PeekHeader (type);
  if (type.IsValid () && type.Get () == aodv::AODVTYPE_RREQ)
    {
      ++sourceRreq;
    }
}
} // namespace

int main (int argc, char **argv)
{
  std::string layout = "chain";
  bool relayForwarding = true;
  CommandLine command;
  command.AddValue ("layout", "chain: 110m range; direct: 250m range", layout);
  command.AddValue ("relayForwarding", "Enable IP forwarding at node 1", relayForwarding);
  command.Parse (argc, argv);
  NS_ABORT_MSG_IF (layout != "chain" && layout != "direct", "Unknown layout");
  const double maxRange = layout == "chain" ? 110.0 : 250.0;
  const bool expectDelivery = layout == "direct" || relayForwarding;
  const uint32_t expectedRelay = layout == "chain" && relayForwarding ? TEST_PACKET_COUNT : 0;

  RngSeedManager::SetSeed (1);
  RngSeedManager::SetRun (1);
  NodeContainer nodes;
  nodes.Create (3);
  MobilityHelper mobility;
  Ptr<ListPositionAllocator> positions = CreateObject<ListPositionAllocator> ();
  positions->Add (Vector (0.0, 0.0, 0.0));
  positions->Add (Vector (100.0, 0.0, 0.0));
  positions->Add (Vector (200.0, 0.0, 0.0));
  mobility.SetPositionAllocator (positions);
  mobility.SetMobilityModel ("ns3::ConstantPositionMobilityModel");
  mobility.Install (nodes);

  YansWifiChannelHelper channel;
  channel.SetPropagationDelay ("ns3::ConstantSpeedPropagationDelayModel");
  channel.AddPropagationLoss ("ns3::RangePropagationLossModel", "MaxRange", DoubleValue (maxRange));
  // Attenuate in-range links too, so received power and PLR cost are realistic
  // negative-dBm / positive-cost values rather than the range model's flat power.
  channel.AddPropagationLoss ("ns3::LogDistancePropagationLossModel",
                              "Exponent", DoubleValue (2.0),
                              "ReferenceLoss", DoubleValue (47.86));
  YansWifiPhyHelper phy = YansWifiPhyHelper::Default ();
  phy.SetChannel (channel.Create ());
  phy.Set ("TxPowerStart", DoubleValue (20.0));
  phy.Set ("TxPowerEnd", DoubleValue (20.0));
  phy.Set ("RxGain", DoubleValue (0.0));
  NqosWaveMacHelper mac = NqosWaveMacHelper::Default ();
  Wifi80211pHelper wifi = Wifi80211pHelper::Default ();
  wifi.SetRemoteStationManager ("ns3::ConstantRateWifiManager",
                                 "DataMode", StringValue ("OfdmRate6MbpsBW10MHz"),
                                 "ControlMode", StringValue ("OfdmRate6MbpsBW10MHz"));
  NetDeviceContainer devices = wifi.Install (phy, mac, nodes);

  AodvHelper aodv;
  aodv.Set ("EnableHello", BooleanValue (false));
  aodv.Set ("EnableEtx", BooleanValue (true));
  aodv.Set ("Alpha", DoubleValue (0.005));
  aodv.Set ("Beta", DoubleValue (60.0));
  InternetStackHelper internet;
  internet.SetRoutingHelper (aodv);
  internet.Install (nodes);
  Ipv4AddressHelper address;
  address.SetBase ("10.2.0.0", "255.255.255.0");
  address.Assign (devices);
  Ptr<Ipv4> relayIp = nodes.Get (1)->GetObject<Ipv4> ();
  relayIp->SetForwarding (relayIp->GetInterfaceForDevice (devices.Get (1)), relayForwarding);

  Ptr<aodv::RoutingProtocol> routing = DynamicCast<aodv::RoutingProtocol> (
      nodes.Get (0)->GetObject<Ipv4> ()->GetRoutingProtocol ());
  NS_ABORT_MSG_IF (!routing, "Expected the PLR AODV routing implementation");
  NS_ABORT_MSG_IF (!routing->TraceConnectWithoutContext ("Tx", MakeCallback (&RoutingTx)),
                   "Cannot connect AODV Tx trace");
  NS_ABORT_MSG_IF (!nodes.Get (0)->GetObject<Ipv4L3Protocol> ()->TraceConnectWithoutContext (
      "Tx", MakeCallback (&SourceTx)), "Cannot connect source IPv4 Tx trace");
  NS_ABORT_MSG_IF (!nodes.Get (1)->GetObject<Ipv4L3Protocol> ()->TraceConnectWithoutContext (
      "UnicastForward", MakeCallback (&RelayForward)), "Cannot connect relay forwarding trace");

  forwardingTrace.open ("forwarding.csv");
  forwardingTrace << "time_s,udp_sequence,forwarder_node,ttl\n";
  AsciiTraceHelper ascii;
  Ptr<OutputStreamWrapper> routeOutput = ascii.CreateFileStream ("routing-tables.txt");
  aodv.PrintRoutingTableAllAt (Seconds (16.0), routeOutput);
  aodv.PrintRoutingTableAllAt (Seconds (27.0), routeOutput);

  UdpServerHelper server (PORT);
  ApplicationContainer serverApps = server.Install (nodes.Get (2));
  serverApps.Start (Seconds (0.0));
  serverApps.Stop (Seconds (29.0));
  UdpClientHelper client (DESTINATION, PORT);
  client.SetAttribute ("MaxPackets", UintegerValue (TEST_PACKET_COUNT));
  client.SetAttribute ("Interval", TimeValue (Seconds (1.0)));
  client.SetAttribute ("PacketSize", UintegerValue (64));
  ApplicationContainer clientApps = client.Install (nodes.Get (0));
  clientApps.Start (Seconds (15.0));
  clientApps.Stop (Seconds (28.0));
  Simulator::Stop (Seconds (30.0));
  Simulator::Run ();

  const uint64_t received = DynamicCast<UdpServer> (serverApps.Get (0))->GetReceived ();
  const uint64_t expectedReceived = expectDelivery ? TEST_PACKET_COUNT : 0;
  const bool passed = received == expectedReceived && relayForward == expectedRelay &&
      forwardedSequences.size () == expectedRelay &&
      (!expectDelivery || sourceTx == TEST_PACKET_COUNT) &&
      (layout != "chain" || sourceRreq > 0);
  std::ofstream summary ("summary.csv");
  summary << "layout,max_range_m,relay_forwarding,source_ip_tx,relay_ip_forward,received,source_rreq,passed\n"
          << layout << ',' << maxRange << ',' << relayForwarding << ',' << sourceTx << ','
          << relayForward << ',' << received << ',' << sourceRreq << ',' << passed << '\n';
  std::cout << "Case: " << layout << "; relay forwarding: " << relayForwarding
            << "; source IP sends: " << sourceTx << "; relay forwards: " << relayForward
            << "; received: " << received << "; source RREQ: " << sourceRreq
            << "; " << (passed ? "PASS" : "FAIL") << std::endl;
  forwardingTrace.close ();
  Simulator::Destroy ();
  return passed ? 0 : 1;
}
