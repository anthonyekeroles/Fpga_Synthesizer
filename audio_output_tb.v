module audio_output_tb();
    reg clk_tb;                      // Clock signal
    reg [13:0] switches_tb;          // Switches for selecting notes and octave
    wire audio_out_tb;               // Output from the module
    
    integer i;
    reg [31:0] cycle_count;          // To count clock cycles between rising edges
    reg [31:0] measured_period;      // Measured period in clock cycles
    real period_ns;                  // Measured period in nanoseconds
    real actual_frequency;           // Actual frequency in Hz
    real expected_frequencies [0:25]; // Array for expected frequencies
    
    // Instantiate the module under test
    audio_output uut (
        .clk(clk_tb),
        .switches(switches_tb),
        .audio_out(audio_out_tb)
    );
    
    // Creating oscillating clock at 10 ns (100 MHz clock)
    localparam period_clk = 10;  // 100 MHz clock
    initial begin
        clk_tb = 0;
        forever #(period_clk / 2) clk_tb = ~clk_tb;
    end

    // Initialize expected frequencies
    initial begin
        // Frequencies for lower and upper octaves
        expected_frequencies[0]  = 262; // C4
        expected_frequencies[1]  = 277; // C#4/Db4
        expected_frequencies[2]  = 294; // D4
        expected_frequencies[3]  = 311; // D#4/Eb4
        expected_frequencies[4]  = 330; // E4
        expected_frequencies[5]  = 349; // F4
        expected_frequencies[6]  = 370; // F#4/Gb4
        expected_frequencies[7]  = 392; // G4
        expected_frequencies[8]  = 415; // G#4/Ab4
        expected_frequencies[9]  = 440; // A4
        expected_frequencies[10] = 466; // A#4/Bb4
        expected_frequencies[11] = 494; // B4
        expected_frequencies[12] = 523; // C5
        // Upper octave frequencies are double the lower octave
        for (i = 13; i < 26; i = i + 1) begin
            expected_frequencies[i] = expected_frequencies[i - 13] * 2.0;
        end
    end
    
    // Test each note and measure the period of audio_out
    initial begin
        $display("Starting test...");
        switches_tb = 14'b0; // Initialize switches to off
        #1011;
        
        // Test each note in both octaves
        for (i = 0; i < 26; i = i + 1) begin
            switches_tb = 14'b0;       // Reset all switches
            switches_tb[i % 13] = 1'b1; // Activate the correct switch
            switches_tb[13] = (i >= 13); // Set upper octave if needed
            #9000001;                  // Wait for a few clock cycles to observe output
            
            // Measure the period of the audio_out signal
            cycle_count = 0;
            measured_period = 0;
            period_ns = 0;
            actual_frequency = 0;
            
            // Wait for the first rising edge
            while (audio_out_tb == 0) begin
                #period_clk;
            end
            while (audio_out_tb == 1) begin
                #period_clk;
            end
            // Start counting clock cycles
            while (audio_out_tb == 0) begin
                cycle_count = cycle_count + 1;
                #period_clk;
            end
            
            // Calculate period and frequency
            measured_period = cycle_count;
            period_ns = measured_period * period_clk;
            actual_frequency = 1.0 / (2 * period_ns / 1000000000.0);
            
            // Compare actual frequency to expected frequency
            if ((actual_frequency >= expected_frequencies[i] - 1.0) && 
                (actual_frequency <= expected_frequencies[i] + 1.0)) begin
                $display("Note %0d: Measured frequency = %0f Hz, Expected frequency = %0f Hz, Test PASSED", 
                         i, actual_frequency, expected_frequencies[i]);
            end else begin
                $display("Note %0d: Measured frequency = %0f Hz, Expected frequency = %0f Hz, Test FAILED", 
                         i, actual_frequency, expected_frequencies[i]);
                     
            end
        end
    end
endmodule
