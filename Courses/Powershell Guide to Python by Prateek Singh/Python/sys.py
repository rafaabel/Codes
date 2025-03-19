import sys
# sys.argv is a list of arguments passed to the script
# sys.argv[0] is by default the path of the script
# and user-defined arguments start with index 1

if len(sys.argv) > 1:
    print('Arguments', sys.argv)
    print('Maximum number is', max(sys.argv[1], sys.argv[2], sys.argv[3]))
    print('argv[0]:', sys.argv[0])
