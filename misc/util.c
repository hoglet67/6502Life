#include <stdio.h>
#include <stdlib.h>

char *skipline(char *pattern) {
   // Skip to end of line
   while (*pattern != 10 && *pattern != 13) {
      pattern++;
   }
   // Skip while space
   while (*pattern == 9 || *pattern == 10 || *pattern == 13 || *pattern == 32) {
      pattern++;
   }
   return pattern;
}

char *readfile(char *filename) {
   FILE *f = fopen(filename, "rb");
   int ret;
   if (f) {
      fseek(f, 0, SEEK_END);
      long fsize = ftell(f);
      fseek(f, 0, SEEK_SET);  //same as rewind(f);
      char *pattern = malloc(fsize + 1);
      ret = fread(pattern, fsize, 1, f);
      fclose(f);
      return pattern;
   } else {
      return 0;
   }
}

