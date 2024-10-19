def largestRectangle(h):
    # Write your code here
    res = 0
    
    for i in range(len(h)):
        length = 0
        for j in range(i, -1, -1):
            if h[j] >= h[i]:
                length += 1
            else:
                break
                
        for j in range(i+1, len(h)):
            if h[j] >= h[i]:
                length += 1
            else:
                break
        
        res = max(res, length*h[i])
            
    return res

if __name__ == '__main__':
    with open('../../input/largest_rectangle.txt', 'r') as file:
        n = int(file.readline().strip())
        heights = list(map(int, file.readline().strip().split()))
        
        result = largestRectangle(heights)
        print(result)
