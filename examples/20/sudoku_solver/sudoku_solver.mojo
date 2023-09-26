from memory.unsafe import Pointer
from memory.buffer import NDBuffer
from utils.list import DimList
from random import randint
from utils.list import VariadicList
from math import sqrt
from math import FPUtils
from benchmark import Benchmark

alias board_size = 9 
alias python_secs = 2.96649886877276e-06

struct Board[grid_size: Int]:
    var data: DTypePointer[DType.uint8]
    var sub_size: Int
    alias elements = grid_size**2

    fn __init__(inout self, *values: Int) raises:
        let args_list = VariadicList(values)
        if len(args_list) != self.elements:
            raise Error(
                "The amount of elements must be equal to the grid_size parameter"
                " squared"
            )

        let sub_size = sqrt(Float64(grid_size))
        if sub_size - sub_size.cast[DType.int64]().cast[DType.float64]() > 0:
            raise Error(
                "The square root of the grid grid_size must be a whole number 9 = 3,"
                " 16 = 4"
            )
        self.sub_size = sub_size.cast[DType.int64]().to_int()

        self.data = DTypePointer[DType.uint8].alloc(grid_size**2)
        for i in range(len(args_list)):
            self.data.simd_store[1](i, args_list[i])

    fn __getitem__(self, row: Int, col: Int) -> UInt8:
        return self.data.simd_load[1](row * grid_size + col)

    fn __setitem__(self, row: Int, col: Int, data: UInt8):
        self.data.simd_store[1](row * grid_size + col, data)

    fn print_board(inout self):
        for i in range(grid_size):
            print(self.data.simd_load[grid_size](i * grid_size))

    fn is_valid(self, row: Int, col: Int, num: Int) -> Bool:
        # Check the given number in the row
        for x in range(grid_size):
            if self[row, x] == num:
                return False

        # Check the given number in the col
        for x in range(grid_size):
            if self[x, col] == num:
                return False

        # Check the given number in the box
        let start_row = row - row % self.sub_size
        let start_col = col - col % self.sub_size
        for i in range(self.sub_size):
            for j in range(self.sub_size):
                if self[i + start_row, j + start_col] == num:
                    return False
        return True

    fn solve(self) -> Bool:
        for i in range(grid_size):
            for j in range(grid_size):
                if self[i, j] == 0:
                    for num in range(1, 10):
                        if self.is_valid(i, j, num):
                            self[i, j] = num
                            if self.solve():
                                return True
                            # If this number leads to no solution, then undo it
                            self[i, j] = 0
                    return False
        return True

fn bench(python_secs: Float64):
    @parameter
    fn init_board() raises -> Board[board_size]:
        return Board[board_size](
            5, 3, 0, 0, 7, 0, 0, 0, 0,
            6, 0, 0, 1, 9, 5, 0, 0, 0,
            0, 9, 8, 0, 0, 0, 0, 6, 0,
            8, 0, 0, 0, 6, 0, 0, 0, 3,
            4, 0, 0, 8, 0, 3, 0, 0, 1,
            7, 0, 0, 0, 2, 0, 0, 0, 6,
            0, 6, 0, 0, 0, 0, 2, 8, 0,
            0, 0, 0, 4, 1, 9, 0, 0, 5,
            0, 0, 0, 0, 8, 0, 0, 7, 9
        )

    fn solve():
        try:
            let board = init_board()
            _ = board.solve()
        except:
            pass

    let mojo_secs = Float64(Benchmark().run[solve]()) / 1e9
    print("mojo seconds:", mojo_secs)
    print("speedup:", python_secs / mojo_secs)

fn main() raises:
    # var board = Board[9](
    # 5, 3, 0, 0, 7, 0, 0, 0, 0,
    # 6, 0, 0, 1, 9, 5, 0, 0, 0,
    # 0, 9, 8, 0, 0, 0, 0, 6, 0,
    # 8, 0, 0, 0, 6, 0, 0, 0, 3,
    # 4, 0, 0, 8, 0, 3, 0, 0, 1,
    # 7, 0, 0, 0, 2, 0, 0, 0, 6,
    # 0, 6, 0, 0, 0, 0, 2, 8, 0,
    # 0, 0, 0, 4, 1, 9, 0, 0, 5,
    # 0, 0, 0, 0, 8, 0, 0, 7, 9
    # )

    # print("Solved:", board.solve())
    # board.print_board()

# Solved: True
# [5, 3, 4, 6, 7, 8, 9, 1, 2]
# [6, 7, 2, 1, 9, 5, 3, 4, 8]
# [1, 9, 8, 3, 4, 2, 5, 6, 7]
# [8, 5, 9, 7, 6, 1, 4, 2, 3]
# [4, 2, 6, 8, 5, 3, 7, 9, 1]
# [7, 1, 3, 9, 2, 4, 8, 5, 6]
# [9, 6, 1, 5, 3, 7, 2, 8, 4]
# [2, 8, 7, 4, 1, 9, 6, 3, 5]
# [3, 4, 5, 2, 8, 6, 1, 7, 9]

    # Benchmarking:
    bench(Float64(python_secs))

# mojo seconds: 0.00026104600000000002
# speedup: 0.011363893217183025