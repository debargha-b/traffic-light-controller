
module traffic_light_controller_adaptive(
    input clk,
    input rst_a,
    input amb_n, amb_s, amb_e, amb_w,
    input [3:0] density_n, density_s, density_e, density_w,
    output reg [2:0] n_lights, s_lights, e_lights, w_lights,
    output reg emergency_mode
);

// Light Encodings
parameter [2:0] RED = 3'b100;
parameter [2:0] YELLOW = 3'b010;
parameter [2:0] GREEN = 3'b001;

// FSM States
parameter [3:0] NORTH_GREEN   = 4'b0000;
parameter [3:0] NORTH_YELLOW  = 4'b0001;
parameter [3:0] SOUTH_GREEN   = 4'b0010;
parameter [3:0] SOUTH_YELLOW  = 4'b0011;
parameter [3:0] EAST_GREEN    = 4'b0100;
parameter [3:0] EAST_YELLOW   = 4'b0101;
parameter [3:0] WEST_GREEN    = 4'b0110;
parameter [3:0] WEST_YELLOW   = 4'b0111;
parameter [3:0] EMERG_WAIT    = 4'b1000;
parameter [3:0] EMERG_N       = 4'b1001;
parameter [3:0] EMERG_S       = 4'b1010;
parameter [3:0] EMERG_E       = 4'b1011;
parameter [3:0] EMERG_W       = 4'b1100;

// Timing parameters
parameter MIN_GREEN = 4;
parameter MAX_GREEN = 12;
parameter YELLOW_TIME = 4;
parameter SAFE_YELLOW = 3;

// Internal registers
reg [3:0] state;
reg [3:0] count;
reg [3:0] green_duration;
reg [1:0] amb_dir;

// Ambulance detection
wire amb_detected;
assign amb_detected = amb_n | amb_s | amb_e | amb_w;

// Function to compute adaptive green time
function [3:0] calc_green;
    input [3:0] density;
    begin
        calc_green = MIN_GREEN + ((MAX_GREEN - MIN_GREEN) * density) / 15;
    end
endfunction

// Main FSM
always @(posedge clk or posedge rst_a) begin
    if (rst_a) begin
        state <= NORTH_GREEN;
        emergency_mode <= 1'b0;
        count <= 4'd0;
        green_duration <= calc_green(density_n);
        amb_dir <= 2'b00;
    end 
    else begin
        // PRIORITY 1: Emergency Detection
        if (amb_detected && !emergency_mode) begin
            emergency_mode <= 1'b1;
            
            // Determine ambulance direction
            if (amb_n) begin
                amb_dir <= 2'b00;
            end else if (amb_s) begin
                amb_dir <= 2'b01;
            end else if (amb_e) begin
                amb_dir <= 2'b10;
            end else if (amb_w) begin
                amb_dir <= 2'b11;
            end
            
            state <= EMERG_WAIT;
            count <= 4'd0;
        end
        
        // PRIORITY 2: Emergency Clear
        else if (emergency_mode && !amb_detected) begin
            emergency_mode <= 1'b0;
            count <= 4'd0;
            
            case (amb_dir)
                2'b00: begin
                    state <= NORTH_YELLOW;
                    green_duration <= calc_green(density_n);
                end
                2'b01: begin
                    state <= SOUTH_YELLOW;
                    green_duration <= calc_green(density_s);
                end
                2'b10: begin
                    state <= EAST_YELLOW;
                    green_duration <= calc_green(density_e);
                end
                2'b11: begin
                    state <= WEST_YELLOW;
                    green_duration <= calc_green(density_w);
                end
            endcase
        end
        
        // PRIORITY 3: Normal FSM Operation
        else begin
            case (state)
                NORTH_GREEN: begin
                    if (count >= green_duration - 1) begin
                        state <= NORTH_YELLOW;
                        count <= 4'd0;
                    end else begin
                        count <= count + 1;
                        green_duration <= calc_green(density_n);
                    end
                end
                
                NORTH_YELLOW: begin
                    if (count >= YELLOW_TIME - 1) begin
                        state <= SOUTH_GREEN;
                        count <= 4'd0;
                        green_duration <= calc_green(density_s);
                    end else begin
                        count <= count + 1;
                    end
                end
                
                SOUTH_GREEN: begin
                    if (count >= green_duration - 1) begin
                        state <= SOUTH_YELLOW;
                        count <= 4'd0;
                    end else begin
                        count <= count + 1;
                        green_duration <= calc_green(density_s);
                    end
                end
                
                SOUTH_YELLOW: begin
                    if (count >= YELLOW_TIME - 1) begin
                        state <= EAST_GREEN;
                        count <= 4'd0;
                        green_duration <= calc_green(density_e);
                    end else begin
                        count <= count + 1;
                    end
                end
                
                EAST_GREEN: begin
                    if (count >= green_duration - 1) begin
                        state <= EAST_YELLOW;
                        count <= 4'd0;
                    end else begin
                        count <= count + 1;
                        green_duration <= calc_green(density_e);
                    end
                end
                
                EAST_YELLOW: begin
                    if (count >= YELLOW_TIME - 1) begin
                        state <= WEST_GREEN;
                        count <= 4'd0;
                        green_duration <= calc_green(density_w);
                    end else begin
                        count <= count + 1;
                    end
                end
                
                WEST_GREEN: begin
                    if (count >= green_duration - 1) begin
                        state <= WEST_YELLOW;
                        count <= 4'd0;
                    end else begin
                        count <= count + 1;
                        green_duration <= calc_green(density_w);
                    end
                end
                
                WEST_YELLOW: begin
                    if (count >= YELLOW_TIME - 1) begin
                        state <= NORTH_GREEN;
                        count <= 4'd0;
                        green_duration <= calc_green(density_n);
                    end else begin
                        count <= count + 1;
                    end
                end
                
                EMERG_WAIT: begin
                    if (count >= SAFE_YELLOW - 1) begin
                        count <= 4'd0;
                        case (amb_dir)
                            2'b00: state <= EMERG_N;
                            2'b01: state <= EMERG_S;
                            2'b10: state <= EMERG_E;
                            2'b11: state <= EMERG_W;
                        endcase
                    end else begin
                        count <= count + 1;
                    end
                end
                
                EMERG_N, EMERG_S, EMERG_E, EMERG_W: begin
                    count <= count + 1;
                end
                
                default: begin
                    state <= NORTH_GREEN;
                    count <= 4'd0;
                    green_duration <= calc_green(density_n);
                end
            endcase
        end
    end
end

// Output Logic (Combinational)
always @(*) begin
    case (state)
        NORTH_GREEN: begin
            n_lights = GREEN;
            s_lights = RED;
            e_lights = RED;
            w_lights = RED;
        end
        
        NORTH_YELLOW: begin
            n_lights = YELLOW;
            s_lights = RED;
            e_lights = RED;
            w_lights = RED;
        end
        
        SOUTH_GREEN: begin
            n_lights = RED;
            s_lights = GREEN;
            e_lights = RED;
            w_lights = RED;
        end
        
        SOUTH_YELLOW: begin
            n_lights = RED;
            s_lights = YELLOW;
            e_lights = RED;
            w_lights = RED;
        end
        
        EAST_GREEN: begin
            n_lights = RED;
            s_lights = RED;
            e_lights = GREEN;
            w_lights = RED;
        end
        
        EAST_YELLOW: begin
            n_lights = RED;
            s_lights = RED;
            e_lights = YELLOW;
            w_lights = RED;
        end
        
        WEST_GREEN: begin
            n_lights = RED;
            s_lights = RED;
            e_lights = RED;
            w_lights = GREEN;
        end
        
        WEST_YELLOW: begin
            n_lights = RED;
            s_lights = RED;
            e_lights = RED;
            w_lights = YELLOW;
        end
        
        EMERG_N: begin
            n_lights = GREEN;
            s_lights = RED;
            e_lights = RED;
            w_lights = RED;
        end
        
        EMERG_S: begin
            n_lights = RED;
            s_lights = GREEN;
            e_lights = RED;
            w_lights = RED;
        end
        
        EMERG_E: begin
            n_lights = RED;
            s_lights = RED;
            e_lights = GREEN;
            w_lights = RED;
        end
        
        EMERG_W: begin
            n_lights = RED;
            s_lights = RED;
            e_lights = RED;
            w_lights = GREEN;
        end
        
        EMERG_WAIT: begin
            n_lights = YELLOW;
            s_lights = YELLOW;
            e_lights = YELLOW;
            w_lights = YELLOW;
        end
        
        default: begin
            n_lights = RED;
            s_lights = RED;
            e_lights = RED;
            w_lights = RED;
        end
    endcase
end

endmodule
