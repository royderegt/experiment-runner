def find_median(ls):
    t_res = []
    order_l = []
    for i, item in enumerate(ls):
        if i == 0:
            order_l.append(item)
        elif item >= order_l[-1]:
            order_l.append(item)
        elif item <= order_l[0]:
            order_l.insert(0, item)
        else:
            length = len(order_l)
            low, high, res = 0, length - 1, -1
            while high >= low:
                middle = (high + low) // 2
                if order_l[middle] == item:
                    res = middle
                    break
                if order_l[middle] > item:
                    if middle > 0 and order_l[middle - 1] < item:
                        res = middle
                        break
                    high = middle - 1
                if order_l[middle] < item:
                    if middle < length - 1 and order_l[middle + 1] > item:
                        res = middle + 1
                        break
                    low = middle + 1
            order_l.insert(res, item)

        length = len(order_l)
        if length % 2 == 1:
            middle = order_l[length // 2]
        else:
            middle = (order_l[length // 2] + order_l[length // 2 - 1]) / 2
        t_res.append('{:.1f}'.format(middle))
    return t_res

if __name__ == "__main__":
    with open('../../input/median_array.txt', 'r') as file:
        n = int(file.readline().strip())  
        numbers = [int(file.readline().strip()) for _ in range(n)]  

    results = find_median(numbers)

    print(results[:10]) 
