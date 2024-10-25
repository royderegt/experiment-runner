#!/bin/python3

#
# Complete the 'fibonacciModified' function below.
#
# The function is expected to return an INTEGER.
# The function accepts following parameters:
#  1. INTEGER t1
#  2. INTEGER t2
#  3. INTEGER n
#

def fibonacciModified(t1, t2, n):
    # Write your code here
    a, b = t1, t2

    if n == 0:
        return (a)
    if n == 1:
        return (b)

    for _ in range(n-2):
        a, b = b, b*b + a

    return b

if __name__ == '__main__':
    with open('/home/roy/Projects/greenlab/experiment-runner/input/fibonacci.txt', 'r') as file:
        t1, t2, n = map(int, file.readline().split())

    result = fibonacciModified(t1, t2, n)
