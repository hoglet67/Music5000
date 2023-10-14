#include <stdio.h>

typedef double REAL;
#define NBQ 2
REAL biquada[]={0.6545294918791053,-1.503352371060256,-0.640959826975052};
REAL biquadb[]={1,2,1};
REAL gain=1;
REAL xyv[]={0,0,0,0,0,0,0,0,0};

REAL applyfilter(REAL v)
{
	int i,b,xp=0,yp=3,bqp=0;
	REAL out=v/gain;
	for (i=8; i>0; i--) {xyv[i]=xyv[i-1];}
	for (b=0; b<NBQ; b++)
	{
		int len=(b==NBQ-1)?1:2;
		xyv[xp]=out;
		for(i=0; i<len; i++) { out+=xyv[xp+len-i]*biquadb[bqp+i]-xyv[yp+len-i]*biquada[bqp+i]; }
		bqp+=len;
		xyv[yp]=out;
		xp=yp; yp+=len+1;
	}
	return out;
}

void main() {
   REAL s = 65535.0;
   for (int i = 0; i < 100; i++) {
      printf("%x\n", (int) applyfilter(s));
   }
}
