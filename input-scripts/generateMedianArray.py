import random

n = 1800000 
random_numbers = [random.randint(1, 1000000) for _ in range(n)]

with open('../input/median_array.txt', 'w') as file:
    file.write(f'{n}\n') 
    for number in random_numbers:
        file.write(f'{number}\n')  
