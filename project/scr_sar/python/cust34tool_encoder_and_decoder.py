#!/usr/bin/env python3
# --------------------------
# author    : aiden song
# date      : 2026/08/03 10:22:03 Monday
# label     : python script
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check|drc_proc|clock_tree_relative_proc)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : This tool converts binary files into OCR-friendly Base34 text and restores original data from encoded strings. 
#             It supports flexible command aliases, automatic output naming and safe file overwrite protection.
# return    : output file
# ref       : link url
# --------------------------
import sys
import os
import argparse

# OCR-friendly alphabet, removed '0' and 'O'
ALPHABET = "123456789ABCDEFGHIJKLMNPQRSTUVWXYZ"
BASE = len(ALPHABET)
LINE_WIDTH = 120
HEADER_LEN = 4
CHAR_MAP = {char: idx for idx, char in enumerate(ALPHABET)}

def show_help():
    help_text = """
Unified Custom Base34 Tool (OCR optimized, exclude '0' and 'O')
Usage: python3 unified_cust34tool.py -m encode|decode -i <inputfile> [OPTIONS]

Mandatory Arguments:
  -m, -mode encode|decode  Select working mode.
                           Valid aliases: encode=e/en ; decode=d/de
  -i, -input FILE          Input file path (must exist)

Optional Arguments:
  -o, -output FILE         Output file path.
                           Mode encode: if omitted, auto name = <inputfile>.enc
                           Mode decode: if omitted, auto name = <inputfile>.dec
  -w, -overwrite           If present, allow overwrite existing output file
  -v, -verbose             Print statistic summary after processing
  -h, -help                Show this help message and exit

Examples:
  Encode: python3 unified_cust34tool.py -m e -i data.bin
  Encode: python3 unified_cust34tool.py -m en -i data.bin -o out.txt -w -v
  Decode: python3 unified_cust34tool.py -m d -i data.bin.enc
  Decode: python3 unified_cust34tool.py -m de -i data.bin.enc -o restore.bin -w -v
"""
    print(help_text)

# ---------------------- Shared core conversion functions (UNCHANGED) ----------------------
def int_to_cust(n: int) -> str:
    if n == 0:
        return ALPHABET[0]
    buf = []
    while n > 0:
        n, rem = divmod(n, BASE)
        buf.append(ALPHABET[rem])
    return "".join(reversed(buf))

def pad_to_fixed(s: str, width: int) -> str:
    return s.rjust(width, ALPHABET[0])[-width:]

def bytes_to_encoded(data: bytes) -> str:
    raw_length = len(data)
    num_data = int.from_bytes(data, byteorder="big")
    str_data = int_to_cust(num_data)
    str_length_header = pad_to_fixed(int_to_cust(raw_length), HEADER_LEN)
    return str_length_header + str_data

def insert_newlines(text: str, line_len: int) -> str:
    chunks = [text[i:i+line_len] for i in range(0, len(text), line_len)]
    return "\n".join(chunks)

def cust_to_int(s: str) -> int:
    value = 0
    for ch in s:
        value = value * BASE + CHAR_MAP[ch]
    return value

def filter_whitespace(text: str) -> str:
    return ''.join(c for c in text if not c.isspace())

def encoded_to_bytes(raw_text: str) -> bytes:
    clean_str = filter_whitespace(raw_text.strip().upper())
    if len(clean_str) < HEADER_LEN:
        raise ValueError("Encoded string is truncated, data corrupted")

    header_segment = clean_str[:HEADER_LEN]
    body_segment = clean_str[HEADER_LEN:]

    target_byte_count = cust_to_int(header_segment)
    data_number = cust_to_int(body_segment)

    if target_byte_count == 0:
        return b""
    return data_number.to_bytes(target_byte_count, byteorder="big")

def normalize_mode(raw_mode: str) -> str:
    """Expand short mode alias to full mode name"""
    raw = raw_mode.lower()
    if raw in ("e", "en", "encode"):
        return "encode"
    elif raw in ("d", "de", "decode"):
        return "decode"
    else:
        raise ValueError(f"Invalid mode '{raw_mode}'. Valid: e/en/encode , d/de/decode")

def main():
    # Trigger help display
    if len(sys.argv) <= 1 or "-h" in sys.argv or "-help" in sys.argv:
        show_help()
        sys.exit(0)

    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument("-m", "-mode", dest="raw_mode", required=True,
                        help="Operation mode: e/en/encode or d/de/decode")
    parser.add_argument("-i", "-input", dest="input", required=True, help="Input file path")
    parser.add_argument("-o", "-output", dest="output", help="Output file path")
    parser.add_argument("-w", "-overwrite", dest="overwrite", action="store_true",
                        help="Allow overwrite if output file exists")
    parser.add_argument("-v", "-verbose", dest="verbose", action="store_true",
                        help="Enable verbose summary")
    args = parser.parse_args()

    # Normalize mode name
    try:
        args.mode = normalize_mode(args.raw_mode)
    except ValueError as e:
        sys.stderr.write(f"ERROR: {str(e)}\n")
        sys.exit(1)

    # Auto assign default output filename
    if args.output is None:
        if args.mode == "encode":
            args.output = f"{args.input}.enc"
        else:
            args.output = f"{args.input}.dec"

    # Check input file existence
    if not os.path.isfile(args.input):
        sys.stderr.write(f"ERROR: Input file [{args.input}] does not exist.\n")
        sys.exit(1)

    # Overwrite protection check
    if os.path.exists(args.output):
        if not args.overwrite:
            sys.stderr.write(
                f"ERROR: Output file [{args.output}] already exists. Use -w to allow overwriting.\n")
            sys.exit(1)

    if args.mode == "encode":
        # Encoding workflow
        try:
            with open(args.input, "rb") as f:
                bin_data = f.read()
        except Exception as e:
            sys.stderr.write(f"ERROR: Failed to read input file: {str(e)}\n")
            sys.exit(1)

        full_encoded_string = bytes_to_encoded(bin_data)
        output_text = insert_newlines(full_encoded_string, LINE_WIDTH)

        try:
            with open(args.output, "w", encoding="ascii") as f:
                f.write(output_text)
        except Exception as e:
            sys.stderr.write(f"ERROR: Failed to write output file: {str(e)}\n")
            sys.exit(1)

        if args.verbose:
            original_size = len(bin_data)
            encoded_chars = len(full_encoded_string)
            line_count = len(output_text.splitlines())
            print("==================== ENCODE SUMMARY ====================")
            print(f"Input File:         {args.input}")
            print(f"Output File:        {args.output}")
            print(f"Original Bytes:     {original_size:,}")
            print(f"Encoded Characters: {encoded_chars:,}")
            print(f"Output Line Count:  {line_count}")
            print(f"Line Width Setting: {LINE_WIDTH}")
            print("========================================================\n")

    elif args.mode == "decode":
        # Decoding workflow
        try:
            with open(args.input, "r", encoding="ascii") as f:
                input_text = f.read()
        except Exception as e:
            sys.stderr.write(f"ERROR: Failed to read input file: {str(e)}\n")
            sys.exit(1)

        try:
            result_binary = encoded_to_bytes(input_text)
        except Exception as e:
            sys.stderr.write(f"DECODING FAILED: {str(e)}\n")
            sys.exit(1)

        try:
            with open(args.output, "wb") as f:
                f.write(result_binary)
        except Exception as e:
            sys.stderr.write(f"ERROR: Failed to write output binary file: {str(e)}\n")
            sys.exit(1)

        if args.verbose:
            clean_data = filter_whitespace(input_text.strip().upper())
            source_char_count = len(clean_data)
            restored_byte_size = len(result_binary)
            print("==================== DECODE SUMMARY ====================")
            print(f"Input Encoded File: {args.input}")
            print(f"Output Binary File: {args.output}")
            print(f"Clean Encoded Chars:{source_char_count:,}")
            print(f"Restored Byte Size: {restored_byte_size:,}")
            print("========================================================\n")

if __name__ == "__main__":
    main()
