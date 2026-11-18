module brainfuck;

import std::io;
import std::io::file;
import std::collections::list;
import std::collections::map;

fn void main(String[] args)
{
  if(args.len < 2)
  {
    io::eprintn("Usage: brainfuck <file.b>");
    return;
  }

  char[]? maybe_bytes = file::load_temp(args[1]);
  if(catch maybe_bytes)
  {
    io::eprintfn("[ERROR]: could not read '%s'", args[1]);
    return;
  }
  String program = (String)maybe_bytes;

  List{char} tape;
  tape.init(mem);
  defer tape.free();
  tape.push(0);
  sz cell_index;

  String user_input;
  sz user_input_pos = 1;

  HashMap{sz,sz} loop_table;
  loop_table.init(mem);
  defer loop_table.free();

  List{sz} loop_stack;
  loop_stack.init(mem);
  defer loop_stack.free();

  for(sz i = 0; i < program.len; i++)
  {
    char c = program[i];
    if(c == '[')
    {
      loop_stack.push(i);
    }
    else if(c == ']')
    {
      if(try start = loop_stack.pop())
      {
        loop_table[start] = i;
        loop_table[i] = start;
      }
      else
      {
        io::eprintfn("[ERROR]: no matching bracket found " +++
                     "for ']' at position %d", i);
        return;
      }
    }
  }

  if(loop_stack.len() != 0)
  {
    io::eprintfn("[ERROR]: no matching bracket found " +++
                 "for '[' at position %d",
                 loop_stack.pop()!!);
    return;
  }

  sz ip = 0;
  while(ip < program.len)
  {
    switch (program[ip])
    {
      case '+':
        tape[cell_index] = tape[cell_index] + 1;
      case '-':
        tape[cell_index] = tape[cell_index] - 1;
      case '<':
        if(cell_index == 0)
        {
          io::eprintn("[ERROR]: moved left of the tape start");
          return;
        }
        cell_index--;
      case '>':
        cell_index++;
        if(cell_index == tape.len())
        {
          tape.push(0);
        }
      case '.':
        io::putchar(tape[cell_index]);
      case ',':
        if(user_input_pos > user_input.len)
        {
          String? line = io::readline(tmem);
          if(try l = line)
          {
            user_input = l;
            user_input_pos = 0;
          }
          else
          {
            tape[cell_index] = 0; // EOF -> 0
            break;
          }
        }
        if(user_input_pos == user_input.len)
        {
          tape[cell_index] = '\n';
        }
        else
        {
          tape[cell_index] = user_input[user_input_pos];
        }
        user_input_pos++;
      case '[':
        if(tape[cell_index] == 0)
        {
          ip = loop_table[ip]!!;
        }
      case ']':
        if(tape[cell_index] != 0)
        {
          ip = loop_table[ip]!!;
        }
      default:
    }
    ip++;
  }

  (void)io::stdout().flush();
}

