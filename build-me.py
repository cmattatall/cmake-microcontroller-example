import os


if __name__ == "__main__":
    os.system("cmake -S . -B build -DCMAKE_TOOLCHAIN_FILE=arm-none-eabi-toolchain.cmake")
    os.system("cmake --build build")
