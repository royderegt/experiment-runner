import random

def generate_large_input():
    n = 7 * 10**6  
    heights = [random.randint(1, 10000) for _ in range(n)] 
    
    with open('../input/largest_rectangle.txt', 'w') as file:
        file.write(f"{n}\n")
        file.write(" ".join(map(str, heights)) + "\n") 

if __name__ == "__main__":
    generate_large_input()
