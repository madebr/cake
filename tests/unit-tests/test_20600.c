
int f(int a[2])
{
    int i;
    i = sizeof(a);
    //warning: sizeof applied to array function parameter
#pragma cake diagnostic check "-Wsizeof-array-argument"    

    static_assert(sizeof(a) == sizeof(void*));
#pragma cake diagnostic check "-Wsizeof-array-argument"    
}

int main()
{
    int i;
    i = sizeof(struct X);
    //error: struct is incomplete type [E74]
#pragma cake diagnostic check "-E74"        
}

