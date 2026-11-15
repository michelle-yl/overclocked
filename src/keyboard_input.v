
module keyboard_input (
    input CLOCK_50,
    input resetn,
    input PS2_CLK,
    input PS2_DAT,
    output reg move_up,
    output reg move_down,
    output reg move_left,
    output reg move_right,
    output reg interact,
    output reg overclock
);

    // Registers used to synchronize the PS/2 clock and data
    reg ps2_clk1, ps2_clk2, prev_ps2_clk;
    reg ps2_dat1, ps2_dat2;

    // Registers used to receive a keyboard packet
    reg [3:0] bit_count;
    reg [7:0] scan_code;
    reg parity_bit;
    reg start_bit;

    // Keeps track of whether the next scan code is a key release
    reg released; 

    // Detect when the PS/2 clock changes from 1 to 0
    wire falling_edge;
    assign falling_edge = prev_ps2_clk & ~ps2_clk2;

    // Synchronize the keyboard signals with the FPGA clock
    always @(posedge CLOCK_50) begin
        ps2_clk1 <= PS2_CLK;
        ps2_clk2 <= ps2_clk1;
        prev_ps2_clk <= ps2_clk2;

        ps2_dat1 <= PS2_DAT;
        ps2_dat2 <= ps2_dat1;
    end

    // Read keyboard data and update the key outputs
    always @(posedge CLOCK_50) begin
        if (!resetn) begin

            // Reset the packet registers
            bit_count <= 0;
            scan_code <= 0;
            parity_bit <= 0;
            start_bit <= 1;
            released <= 0;

            // Initially, no keys are pressed
            move_up <= 0;
            move_down <= 0;
            move_left <= 0;
            move_right <= 0;
            interact <= 0;
            overclock <= 0;
        end

        // Read one bit whenever the PS/2 clock falls
        else if (falling_edge) begin

            // First bit is the start bit
            if (bit_count == 0)
                start_bit <= ps2_dat2;

            // Next 8 bits contain the key scan code
            if (bit_count >= 1 && bit_count <= 8)
                scan_code[bit_count - 1] <= ps2_dat2;

            // Ninth bit is used to check parity
            if (bit_count == 9)
                parity_bit <= ps2_dat2;

            // Last bit is the stop bit
            if (bit_count == 10) begin
                bit_count <= 0;

                // Only accept a packet with valid start, stop, and parity bits
                if (start_bit == 0 && ps2_dat2 == 1 &&
                    (^scan_code ^ parity_bit) == 1) begin

                    // F0 means the next key code represents a release
                    if (scan_code == 8'hF0)
                        released <= 1;

                    else begin

                        // Set a key output to 1 when pressed and 0 when released
                        if (scan_code == 8'h1D)
                            move_up <= !released;      // W

                        else if (scan_code == 8'h1B)
                            move_down <= !released;    // S

                        else if (scan_code == 8'h1C)
                            move_left <= !released;    // A

                        else if (scan_code == 8'h23)
                            move_right <= !released;   // D

                        else if (scan_code == 8'h29)
                            interact <= !released;     // Space

                        else if (scan_code == 8'h12)
                            overclock <= !released;    // Left Shift

                        // Finished processing the press or release
                        released <= 0;
                    end
                end
            end

            // Move to the next bit of the packet
            else
                bit_count <= bit_count + 1'b1;
        end
    end

endmodule
