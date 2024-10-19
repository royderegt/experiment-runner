def largestRectangle(h):
    max_area = 0
    n = len(h)
    
    for i in range(n):
        # Initialize the length of the rectangle
        length = 1
        
        # Expand left
        for j in range(i - 1, -1, -1):
            if h[j] >= h[i]:
                length += 1
            else:
                break
        
        # Expand right
        for j in range(i + 1, n):
            if h[j] >= h[i]:
                length += 1
            else:
                break
        
        # Calculate area with the current height
        area = length * h[i]
        max_area = max(max_area, area)
    
    return max_area

if __name__ == '__main__':
    with open('../../input/largest_rectangle.txt', 'r') as file:
        n = int(file.readline().strip())
        heights = list(map(int, file.readline().strip().split()))
        
        result = largestRectangle(heights)
        print(result)
