`include "ALU/ALU.v"
`include "Controller/Control_unit.v"
`include "Data Memory/Data_memory.v"
`include "Instruction memory/instruction_memory.v"
`include "PC/PC.v"
`include "Register file/Register_file.v"
`include "Sign Extender/Sign_Extender.v"

module RISC_V_Processor
(
    input clk,
    input reset_input 
);
    //control Signals
    wire reset_control,PC_Src;
    wire Reg_write;
    wire ImmSrc;
    wire ALU_Src;
    wire zero;
    wire [2:0] ALU_Control;
    wire Mem_wirte;
    wire Result_Src;

    //control Unit
    Control_unit controller(
        //reset the processor
        .rst(reset_input),
        //instruction
        .op_code(Instruction[6:0]),//inst[6:0]
        .funct3(Instruction[14:12]), //inst[14:12]
        .funct7(Instruction[30]), //inst[30]
        //Data memory 
        .Mem_wirte(Mem_wirte),
        //ALU 
        .zero(zero),
        .ALU_Control(ALU_Control),
        //PC
        .reset(reset_control),
        .PC_Src(PC_Src),
        //Register file
        .Reg_write(Reg_write), 
        //sign extender
        .ImmSrc(ImmSrc),
        //Different MUX in the processor
        .ALU_Src(ALU_Src),
        .Result_Src(Result_Src)
        );


    //data path signals
    wire [31:0] PC_out;
    wire [31:0] Instruction;
    
    wire [31:0] Reg_out_1;
    wire [31:0] Reg_out_2;
    wire [31:0] Reg_In;

    wire [31:0] Sign_extended;

    wire [31:0] ALU_In;
    wire [31:0] ALU_Result;
    wire [31:0] Data_Mem_out;

    //PC
        PC Program_Counter(
            .clk(clk),
            //control Signals
            .reset(reset_control),.PC_Src(PC_Src),
            //data path signals
            .PC_in(Sign_extended),
            .PC_out(PC_out) 
            );
    //instruction memory
        instruction_memory Instr_Mem (
            .clk(clk),
            //data path signals
            .PC_out_address(PC_out),
            .instruction(Instruction)
            );
    //Register File
        Register_file Reg_file(
            .clk(clk),
            //Data path signals
            .A1(Instruction[19:15]),.RD1(Reg_out_1),
            .A2(Instruction[24:20]),.RD2(Reg_out_2),
            .A3(Instruction[11:7] ),.WD1(Reg_In),
            //Control Signal
            .WE(Reg_write),
            );
    //Sign Extender
        sign_extender Immediate_creator(
            //control Signal
            .ImmSrc(ImmSrc),
            //data path signal
            .data_in(Instruction),
            .data_out(Sign_extended)
            ); 
    //ALU Source MUX
        always @(*) 
        begin
            case (ALU_Src)
            1'b0: ALU_In = Reg_out_2;
            1'b1: ALU_In = Sign_extended;  
            default: ALU_In = 32'b0;
            endcase    
        end 
    //ALU 
        ALU exe_block(
            //data path signals
            .SrcA(Reg_out_1),
            .SrcB(ALU_In),
            .ALU_result(ALU_Result),
            //control signals
            .zero(zero),
            .ALU_Control(ALU_Control)
            );    
    //Data Memory
        Data_memory Data_Mem(
            .clk(clk),
            //Data Path Signal
            .A(ALU_Result),
            .WD(Reg_out_2),
            .RD(Data_Mem_out),
            //control signal
            .WE(Mem_wirte)
            );       
    //Register In Source Mux
         always @(*) 
        begin
            case (Result_Src)
            1'b0: Reg_In = ALU_Result;
            1'b1: Reg_In = Data_Mem_out;  
            default: Reg_In = 32'b0;
            endcase    
        end    



endmodule