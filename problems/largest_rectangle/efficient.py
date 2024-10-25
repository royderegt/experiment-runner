def largestRectangle(h):
    max_area = 0
    n = len(h)
    
    # Arrays to store the left and right limits for each height
    left_limit = [0] * n
    right_limit = [0] * n
    
    # Fill left limits
    for i in range(n):
        if i == 0:
            left_limit[i] = 0
        else:
            j = i - 1
            while j >= 0 and h[j] >= h[i]:
                j -= 1
            left_limit[i] = j + 1
    
    # Fill right limits
    for i in range(n - 1, -1, -1):
        if i == n - 1:
            right_limit[i] = n - 1
        else:
            j = i + 1
            while j < n and h[j] >= h[i]:
                j += 1
            right_limit[i] = j - 1
    
    # Calculate the maximum area using the limits
    for i in range(n):
        width = right_limit[i] - left_limit[i] + 1
        area = width * h[i]
        max_area = max(max_area, area)
    
    return max_area

if __name__ == '__main__':
    with open('/home/roy/Projects/greenlab/experiment-runner/input/largest_rectangle.txt', 'r') as file:
        n = int(file.readline().strip())
        heights = list(map(int, file.readline().strip().split()))
        
        result = largestRectangle(heights)
        print(result)
