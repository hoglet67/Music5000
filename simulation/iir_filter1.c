#include <stdio.h>
#include <stdint.h>

typedef int64_t REAL;

#define W_FRAC 16

#define NBQ 2
REAL biquada[]={
   (int)(0.6545294918791053 * (1 << W_FRAC) + 0.5),
   (int)(-1.503352371060256 * (1 << W_FRAC) - 0.5),
   (int)(-0.640959826975052 * (1 << W_FRAC) - 0.5),
};
REAL biquadb[]={
   (int)(1 * (1 << W_FRAC)),
   (int)(2 * (1 << W_FRAC)),
   (int)(1 * (1 << W_FRAC)),
};
REAL gain=1;
REAL xyv[]={0,0,0,0,0,0,0,0,0};

REAL applyfilter(REAL v)
{
	int i,b,xp=0,yp=3,bqp=0;
	REAL out=v/gain;
	for (i=8; i>0; i--) {xyv[i]=xyv[i-1]; }
	for (b=0; b<NBQ; b++)
	{
		int len=(b==NBQ-1)?1:2;
		xyv[xp]=out;
		for(i=0; i<len; i++) { out+=(xyv[xp+len-i]*biquadb[bqp+i]-xyv[yp+len-i]*biquada[bqp+i]) >> W_FRAC; }
		bqp+=len;
		xyv[yp]=out;
		xp=yp; yp+=len+1;
	}
   for (i = 0; i < 8; i++) {
      printf("%d=%lx\n", i, xyv[i]);
   }
   printf("out=%lx\n", out);
   printf("\n");
	return out;
}

void main() {
   REAL s = 65535.0;
   for (int i = 0; i < 3; i++) {
      printf("%ld\n", biquadb[i]);
   }
   for (int i = 0; i < 3; i++) {
      printf("%ld\n", -biquada[i]);
   }

   for (int i = 0; i < 100; i++) {
      printf("%ld\n", (uint64_t) applyfilter(s) >> 7);
   }
}
