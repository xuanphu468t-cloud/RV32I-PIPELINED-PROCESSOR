module top_tb();
    logic clk;
    logic reset;
    logic [31:0] WriteData, DataAdr;
    logic MemWrite;

    top dut(clk, reset, WriteData, DataAdr, MemWrite);

    // Khởi tạo Reset
    initial begin
        reset <= 1; 
        #22; 
        reset <= 0;   
    end

    initial begin   
        $dumpfile("top.vcd");
        $dumpvars(0, top_tb);
    end

    // Tạo xung Clock
    always begin
        clk <= 1; #5; 
        clk <= 0; #5;
    end

    // Kiểm tra kết quả ghi RAM
    always @(negedge clk) begin
        if (MemWrite) begin
            // Trường hợp THÀNH CÔNG: Ghi giá trị 25 vào địa chỉ 100
            if (DataAdr === 100 && WriteData === 25) begin
                $display("====================================");
                $display("  SIMULATION SUCCESSFUL / COMPLETED!");
                $display("====================================");
                $finish; // Dừng hẳn mô phỏng
            end 
            // Trường hợp THẤT BẠI: Ghi vào địa chỉ 100 nhưng sai dữ liệu
            else if (DataAdr === 100 && WriteData !== 25) begin
                $display("====================================");
                $display("  SIMULATION FAILED! (Wrong Data: %d)", WriteData);
                $display("====================================");
                $finish;
            end
        end
    end

    // Giới hạn thời gian mô phỏng (Timeout phòng trường hợp treo loop)
    initial begin
        #10000;
        $display("====================================");
        $display("  SIMULATION TIMEOUT (Check your PC or program flow)");
        $display("====================================");
        $finish;
    end
endmodule