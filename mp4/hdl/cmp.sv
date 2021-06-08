import rv32i_types::*;
module cmp(
      input rv32i_word first,
      input rv32i_word second,
		input [2:0] cmpop,
      output logic out
);

always_comb begin
      unique case (cmpop)
            rv32i_types::beq:       out = (first == second);
            rv32i_types::bne:       out = (first != second);
            rv32i_types::blt:       out = ($signed(first) < $signed(second));
            rv32i_types::bge:       out = ($signed(first) >= $signed(second));
            rv32i_types::bltu:      out = ($unsigned(first) < $unsigned(second));
            rv32i_types::bgeu:      out = ($unsigned(first) >= $unsigned(second));
            default:                out = 1'b0; // ?
      endcase
end

endmodule