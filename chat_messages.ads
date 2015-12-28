with Lower_Layer_UDP;
with Ada.Strings.Unbounded;

package Chat_Messages is
	package ASU renames Ada.Strings.Unbounded;
	package LLU renames Lower_Layer_UDP;

	type Client is record
		Client_EP: LLU.End_Point_Type;
		Nick_Name: ASU.Unbounded_String;
		Lector: Boolean;
	end record;
	type Mult_Client is array (0..50 - 1) of Client;

	type Message_Type is (Init, Writer, Server);

end Chat_Messages;
