import heapq

class RunningMedian:
    def __init__(self):
        self.max_heap = []  # Max-heap for the lower half
        self.min_heap = []  # Min-heap for the upper half

    def add(self, num):
        if not self.max_heap or num < -self.max_heap[0]:
            heapq.heappush(self.max_heap, -num)
        else:
            heapq.heappush(self.min_heap, num)

        # Rebalance heaps if necessary
        if len(self.max_heap) > len(self.min_heap) + 1:
            heapq.heappush(self.min_heap, -heapq.heappop(self.max_heap))

        if len(self.min_heap) > len(self.max_heap):
            heapq.heappush(self.max_heap, -heapq.heappop(self.min_heap))

    def find_median(self):
        if len(self.max_heap) == len(self.min_heap):
            return (-self.max_heap[0] + self.min_heap[0]) / 2.0  # Negate max_heap's top to get the original value
        else:
            return float(-self.max_heap[0])  # Negate max_heap's top to get the original value

def runningMedian(a):
    running_median = RunningMedian()
    medians = []

    for num in a:
        running_median.add(num)
        medians.append(running_median.find_median())

    return medians

if __name__ == "__main__":
    with open('/home/roy/Projects/greenlab/experiment-runner/input/median_array.txt', 'r') as file:
        n = int(file.readline().strip())  
        numbers = [int(file.readline().strip()) for _ in range(n)] 

    results = runningMedian(numbers)

    print(results[:10]) 
