#!/usr/bin/env python3
import sys
import argparse
import chnutils

def little_formatter(bytesperel=2):
    def inner(s):
        b = bytearray()
        shifts = list(range(0, bytesperel, 8))
        for el in s:
            b.extend((el >> shift) for shift in shifts)
        return b
    return inner

def big_formatter(bytesperel=2):
    def inner(s):
        b = bytearray()
        shifts = list(range(bytesperel - 8, -8, -8))
        for el in s:
            b.extend((el >> shift) for shift in shifts)
        return b
    return inner

outformats = [
    ('ascii', '', lambda it: ('%d\n' % x for x in it)),
    ('u8', 'b', bytes),
    ('u16le', 'b', little_formatter(2)),
    ('u16be', 'b', big_formatter(2)),
    ('u24le', 'b', little_formatter(3)),
    ('u24be', 'b', big_formatter(3)),
    ('u32le', 'b', little_formatter(4)),
    ('u32be', 'b', big_formatter(4)),
]
invoutformats = {name: (mode, fmt) for name, mode, fmt in outformats}

def parse_argv(argv):
    tformats = ', '.join(row[0] for row in outformats)
    parser = argparse.ArgumentParser()
    parser.add_argument("INFILE",
                        help="binary file to be deduplicated (- for piped input)")
    parser.add_argument("UNIQFILE",
                        help="file to which unique blocks are written")
    parser.add_argument("MAPFILE", default='-',
                        help="file listing indices into UNIQFILE")
    parser.add_argument("-c", "--block-size",
                        metavar="NUMBYTES", type=int, default=16,
                        help="number of bytes per block")
    parser.add_argument("--format", metavar="MAPFORMAT", default='ascii',
                        choices=[row[0] for row in outformats],
                        help="set map format (%s)" % tformats)
    parser.add_argument("--map-base", metavar="MAPADD", type=int, default=0,
                        help="number to add to each map entry")
    return parser.parse_args(argv[1:])

def main(argv=None):
    args = parse_argv(argv or sys.argv)

    if args.INFILE == '-':
        data = sys.stdin.buffer.read()
    else:
        with open(args.INFILE, 'rb') as infp:
            data = infp.read()

    data = [data[i:i + args.block_size]
            for i in range(0, len(data), args.block_size)]
    deduped, nam = chnutils.dedupe_chr(data)
    deduped = b''.join(deduped)
    mapisbinary, mapfmt = invoutformats[args.format]
    namfmt = mapfmt(i + args.map_base for i in nam)

    if args.UNIQFILE == '-':
        sys.stdout.buffer.write(deduped)
    else:
        with open(args.UNIQFILE, 'wb') as outfp:
            outfp.write(deduped)

    if args.MAPFILE == '-':
        if mapisbinary:
            sys.stdout.buffer.write(namfmt)
        else:
            sys.stdout.write(namfmt)
    else:
        with open(args.MAPFILE, 'wb' if mapisbinary else 'w') as outfp:
            outfp.write(namfmt)

if __name__=='__main__':
    main()
