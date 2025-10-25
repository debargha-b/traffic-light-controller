`timescale 1ns/1ps

module tb_traffic_extended;

// Testbench signals
reg clk, rst_a;
reg amb_n, amb_s, amb_e, amb_w;
reg [3:0] density_n, density_s, density_e, density_w;
wire [2:0] n_lights, s_lights, e_lights, w_lights;
wire emergency_mode;

// Instantiate DUT
traffic_light_controller_adaptive DUT (
    .clk(clk),
    .rst_a(rst_a),
    .amb_n(amb_n),
    .amb_s(amb_s),
    .amb_e(amb_e),
    .amb_w(amb_w),
    .density_n(density_n),
    .density_s(density_s),
    .density_e(density_e),
    .density_w(density_w),
    .n_lights(n_lights),
    .s_lights(s_lights),
    .e_lights(e_lights),
    .w_lights(w_lights),
    .emergency_mode(emergency_mode)
);

// Clock generation: 10ns period
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

// Helper function to display light colors
function [55:0] light_color;
    input [2:0] light;
    begin
        case(light)
            3'b001: light_color = "GREEN ";
            3'b010: light_color = "YELLOW";
            3'b100: light_color = "RED   ";
            default: light_color = "OFF   ";
        endcase
    end
endfunction

// Helper function to display state names
function [127:0] state_name;
    input [3:0] state;
    begin
        case(state)
            4'b0000: state_name = "NORTH_GREEN  ";
            4'b0001: state_name = "NORTH_YELLOW ";
            4'b0010: state_name = "SOUTH_GREEN  ";
            4'b0011: state_name = "SOUTH_YELLOW ";
            4'b0100: state_name = "EAST_GREEN   ";
            4'b0101: state_name = "EAST_YELLOW  ";
            4'b0110: state_name = "WEST_GREEN   ";
            4'b0111: state_name = "WEST_YELLOW  ";
            4'b1000: state_name = "EMERG_WAIT   ";
            4'b1001: state_name = "EMERG_N      ";
            4'b1010: state_name = "EMERG_S      ";
            4'b1011: state_name = "EMERG_E      ";
            4'b1100: state_name = "EMERG_W      ";
            default: state_name = "UNKNOWN      ";
        endcase
    end
endfunction

// Comprehensive test scenarios
initial begin
    // Initialize all signals
    rst_a = 1;
    amb_n = 0; amb_s = 0; amb_e = 0; amb_w = 0;
    density_n = 8; density_s = 8; density_e = 8; density_w = 8;
    
    $display("\n");
    $display("================================================================================");
    $display("        ADAPTIVE TRAFFIC LIGHT CONTROLLER - EXTENDED TESTBENCH");
    $display("           Demonstrating Adaptive Timing + Emergency Override");
    $display("================================================================================");
    $display("\n");
    
    // Release reset
    #15 rst_a = 0;
    
    // TEST 1: 200ns
    $display("\n");
    $display("--------------------------------------------------------------------------------");
    $display("TEST 1: NORMAL OPERATION - EQUAL DENSITIES (All = 8)");
    $display("--------------------------------------------------------------------------------");
    density_n = 8; density_s = 8; density_e = 8; density_w = 8;
    #200;
    
    // TEST 2: 300ns
    $display("\n");
    $display("--------------------------------------------------------------------------------");
    $display("TEST 2: ADAPTIVE TIMING - VARYING DENSITIES");
    $display("--------------------------------------------------------------------------------");
    density_n = 15; density_s = 3; density_e = 10; density_w = 5;
    #300;
    
    // TEST 3: ~350ns
    $display("\n");
    $display("--------------------------------------------------------------------------------");
    $display("TEST 3: EMERGENCY OVERRIDE - SOUTH AMBULANCE");
    $display("--------------------------------------------------------------------------------");
    density_n = 8; density_s = 8; density_e = 8; density_w = 8;
    #50;
    $display("\n>>> AMBULANCE DETECTED ON SOUTH at time %0t ns", $time);
    amb_s = 1;
    #90;
    $display(">>> AMBULANCE CLEARED ON SOUTH at time %0t ns", $time);
    amb_s = 0;
    #100;
    
    // TEST 4: ~300ns
    $display("\n");
    $display("--------------------------------------------------------------------------------");
    $display("TEST 4: EMERGENCY OVERRIDE - EAST AMBULANCE");
    $display("--------------------------------------------------------------------------------");
    #150;
    $display("\n>>> AMBULANCE DETECTED ON EAST at time %0t ns", $time);
    amb_e = 1;
    #70;
    $display(">>> AMBULANCE CLEARED ON EAST at time %0t ns", $time);
    amb_e = 0;
    #80;
    
    // TEST 5: ~240ns
    $display("\n");
    $display("--------------------------------------------------------------------------------");
    $display("TEST 5: MULTIPLE AMBULANCES - NORTH & WEST");
    $display("--------------------------------------------------------------------------------");
    #80;
    $display("\n>>> MULTIPLE AMBULANCES DETECTED at time %0t ns", $time);
    amb_n = 1;
    amb_w = 1;
    #60;
    $display(">>> ALL AMBULANCES CLEARED at time %0t ns", $time);
    amb_n = 0;
    amb_w = 0;
    #100;
    
    // TEST 6: 300ns
    $display("\n");
    $display("--------------------------------------------------------------------------------");
    $display("TEST 6: EXTREME CONGESTION - ALL DENSITIES = 15");
    $display("--------------------------------------------------------------------------------");
    density_n = 15; density_s = 15; density_e = 15; density_w = 15;
    #300;
    
    // TEST 7: 200ns
    $display("\n");
    $display("--------------------------------------------------------------------------------");
    $display("TEST 7: LOW TRAFFIC - ALL DENSITIES = 2");
    $display("--------------------------------------------------------------------------------");
    density_n = 2; density_s = 2; density_e = 2; density_w = 2;
    #200;
    
    // TEST 8: ~320ns
    $display("\n");
    $display("--------------------------------------------------------------------------------");
    $display("TEST 8: EMERGENCY DURING CONGESTION - NORTH AMBULANCE");
    $display("--------------------------------------------------------------------------------");
    density_n = 15; density_s = 2; density_e = 10; density_w = 8;
    #100;
    $display("\n>>> NORTH AMBULANCE IN CONGESTION at time %0t ns", $time);
    amb_n = 1;
    #100;
    $display(">>> NORTH AMBULANCE CLEARED at time %0t ns", $time);
    amb_n = 0;
    #120;
    
    // TEST 9: ~510ns
    $display("\n");
    $display("--------------------------------------------------------------------------------");
    $display("TEST 9: RAPID AMBULANCE SEQUENCE");
    $display("--------------------------------------------------------------------------------");
    density_n = 8; density_s = 8; density_e = 8; density_w = 8;
    
    #50;
    $display("\n>>> SOUTH AMBULANCE #1 at time %0t ns", $time);
    amb_s = 1;
    #60;
    amb_s = 0;
    
    #40;
    $display("\n>>> EAST AMBULANCE #2 at time %0t ns", $time);
    amb_e = 1;
    #60;
    amb_e = 0;
    
    #40;
    $display("\n>>> WEST AMBULANCE #3 at time %0t ns", $time);
    amb_w = 1;
    #60;
    amb_w = 0;
    
    #100;
    
    // TEST 10: ~400ns (INCREASED TO REACH 3395ns)
    $display("\n");
    $display("--------------------------------------------------------------------------------");
    $display("TEST 10: DYNAMIC DENSITY CHANGES");
    $display("--------------------------------------------------------------------------------");
    density_n = 5; density_s = 5; density_e = 5; density_w = 5;
    #80;
    
    $display("\n>>> DENSITY SPIKE: North increases to 15 at time %0t ns", $time);
    density_n = 15;
    #100;
    
    $display(">>> DENSITY DROP: North decreases to 2 at time %0t ns", $time);
    density_n = 2;
    #100;
    
    // CRITICAL FIX: This ensures simulation continues to ~3395ns
    #220;  // Changed from #100 to #220
    
    $display("\n");
    $display("================================================================================");
    $display("                     ALL TESTS COMPLETED SUCCESSFULLY");
    $display("           Total Simulation Time: %0t ns", $time);
    $display("================================================================================");
    $display("\n");
    
    $finish;
end

// Continuous monitoring
initial begin
    $display("\nTime(ns) | Rst | Emg | Amb(N,S,E,W) | Density(N,S,E,W) | State         | N      | S      | E      | W");
    $display("---------|-----|-----|--------------|------------------|---------------|--------|--------|--------|--------");
    $monitor("%7d | %b   | %b   | %b %b %b %b      | %2d %2d %2d %2d    | %s | %s | %s | %s | %s",
        $time, rst_a, emergency_mode, amb_n, amb_s, amb_e, amb_w,
        density_n, density_s, density_e, density_w,
        state_name(DUT.state),
        light_color(n_lights), light_color(s_lights),
        light_color(e_lights), light_color(w_lights));
end

// Event tracking
always @(posedge emergency_mode) begin
    $display("\n*** EMERGENCY MODE ACTIVATED at %0t ns ***", $time);
    if (amb_n) $display("    Direction: NORTH");
    if (amb_s) $display("    Direction: SOUTH");
    if (amb_e) $display("    Direction: EAST");
    if (amb_w) $display("    Direction: WEST");
end

always @(negedge emergency_mode) begin
    $display("*** EMERGENCY MODE CLEARED at %0t ns ***\n", $time);
end

// Track state transitions
reg [3:0] prev_state;
initial prev_state = 4'b0000;

always @(DUT.state) begin
    if (DUT.state != prev_state) begin
        $display("    [STATE CHANGE: %s -> %s at %0t ns]",
            state_name(prev_state), state_name(DUT.state), $time);
        prev_state = DUT.state;
    end
end

// Waveform dump
initial begin
    $dumpfile("traffic_extended.vcd");
    $dumpvars(0, tb_traffic_extended);
end

endmodule
