/*
 * function.c
 *
 *  Created on: 2019年8月14日
 *      Author: lss
 */


#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include<string.h>
#include "math.h"
#define PI 3.1415926535

/*****************filter**********************************/
/*****************y=filter([1 -0.9375],1,x)***************/
#ifndef EPS
#define EPS 0.000001
#endif

void filter(const double* x, double* y, int xlen, double* a, double* b, int nfilt)
{
	double tmp;
	int i,j;

	if( (*a-1.0>EPS) || (*a-1.0<-EPS) )
	{
		tmp=*a;
		for(i=0;i<nfilt;i++)
		{
			b[i]/=tmp;
		}
		a[0]/=tmp;
	}

	memset(y,0,xlen*sizeof(double));

	a[0]=0.0;
	for(i=0;i<xlen;i++)
	{
		for(j=0;i>=j&&j<nfilt;j++)
		{
			if(j>0)
			{
				y[i] += b[j]*x[i-j];
			}
			else
			{
				y[i] += (b[j]*x[i-j]-a[j]*y[i-j]);
			}
		}
	}
    a[0]=1.0;
}

/***********************short_energy*********************/
double shortenergy(double* sampledata,unsigned int windowlen)
{
	/*windowlen       窗点数
	 *overlop         窗移动点数
	 *sampledata      信号输入（1536）
	 */
//	unsigned int windowlen = 512;
//	unsigned overlop   = 40;
	double filtdata[windowlen];
	double amp=0;    //全局变量
	double a[1] = {1};
	double b[2];
	int j;
	b[0]=1;
	b[1]=-0.9375;
	filter(sampledata,filtdata,windowlen,a,b,2);
	for(j=0;j<windowlen;j++)
	{
		if(filtdata[j]>=0)
		{
			amp += filtdata[j];
		}
		else
		{
			amp += -filtdata[j];
		}
	}
	return amp;
}

/******************polyfit()************************/
void polyfit(int n,double x[],double y[],int poly_n,double a[])
{
	int i,j,l;
	int temp0;
	void gauss_solve(int n,double A[],double x[],double b[]);

	double tempx[n];
	temp0=poly_n*2+1;
	double sumxx[temp0];
	double tempy[n];
	double sumxy[poly_n+1];
	temp0=(poly_n+1)*(poly_n+1);
	double ata[temp0];

	for (i=0;i<n;i++)
	{
		tempx[i]=1;
		tempy[i]=y[i];
	}
	for (i=0;i<2*poly_n+1;i++)
		 for (sumxx[i]=0,j=0;j<n;j++)
		{
			sumxx[i]+=tempx[j];
			tempx[j]*=x[j];
		}
	for (i=0;i<poly_n+1;i++)
		for (sumxy[i]=0,j=0;j<n;j++)
		{
			sumxy[i]+=tempy[j];
			tempy[j]*=x[j];
		}
	for (i=0;i<poly_n+1;i++)
	{
		 for (l=0;l<poly_n+1;l++)
		 {
			ata[i*(poly_n+1)+l]=sumxx[i+l];
		 }
	}
	gauss_solve(poly_n+1,ata,a,sumxy);
}

/*************gauss_solve******************/
void gauss_solve(int n,double A[],double x[],double b[])
{
	int i,j,k,r;
	double max;
	for (k=0;k<n-1;k++)
	{
		max=fabs(A[k*n+k]); /*find maxmum*/
		r=k;
		for (i=k+1;i<n-1;i++)
			if (max<fabs(A[i*n+i]))
			{
				max=fabs(A[i*n+i]);
				r=i;
			}
		if (r!=k)
			for (i=0;i<n;i++)         /*change array:A[k]&A[r] */
			{
				max=A[k*n+i];
				A[k*n+i]=A[r*n+i];
				A[r*n+i]=max;
			}
		max=b[k];                    /*change array:b[k]&b[r]     */
		b[k]=b[r];
		b[r]=max;
		for (i=k+1;i<n;i++)
		{
			for (j=k+1;j<n;j++)
			{
				A[i*n+j]-=A[i*n+k]*A[k*n+j]/A[k*n+k];
			}
			b[i]-=A[i*n+k]*b[k]/A[k*n+k];
		}
	}
	for (i=n-1;i>=0;x[i]/=A[i*n+i],i--)
		 for (j=i+1,x[i]=b[i];j<n;j++)
			 x[i]-=A[i*n+j]*x[j];
}

/****************GetSlop()***********************/
double GetSlop(double *amp,int datalen)
{
	/*length(amp)       数据长度100
	 *overlop=20               窗移动数据20
	 */
	int i;
    double x[datalen];
	double slop[2];

    for(i=0;i<datalen;i++)
    {
    	x[i] = i+1;
    }
	polyfit(datalen,x,amp,1,slop);
	if(slop[1]<0)
	{
		slop[1]=0;
	}
	return slop[1]*100;
}

/************Three-level central clipping*******************/
/* sampledata 信号输入
 * datalen    信号长度
 */
void ThreeCentralClip(double *sampledata,int datalen,double *data_out0,double *data_out1)
{
	double C=0;
	double data1[datalen/2],data2[datalen/2];
	int i;

	for(i=0;i<datalen/2;i++)
	{
		data1[i] = sampledata[i];
		data2[i] = sampledata[i+datalen/2];
	}

	for(i=1;i<datalen/2;i++)
	{
		if(data1[i]>data1[0])
		{
			data1[0] = data1[i];
		}
		if(data2[i]>data2[0])
		{
			data2[0] = data2[i];
		}
	}
	//求削波门限C
	if(data1[0]>data2[0])
	{
		C = 0.68*data2[0];
	}
	else
	{
		C = 0.68*data1[0];
	}
    //削波：tempdata:大于C的取1，小于-C的取-1，其余为0;sampledata:大于C的减去C，小于-C的加C，其他的取0；
	for(i=0;i<datalen;i++)
	{
		if(sampledata[i]>C)
		{
			data_out0[i] = sampledata[i] - C;
			data_out1[i] = 1;
		}
		else if(sampledata[i]<-C)
		{
			data_out0[i] = sampledata[i] + C;
			data_out1[i] = -1;
		}
		else
		{
			data_out0[i] = 0;
			data_out1[i] = 0;
		}
	}
}

/************correction*******************/
/* data1      第一路信号输入
 * data2      第二路信号输入
 * datalen    信号长度
 * data_out   相关输出（2*datalen-1）
 */
void GetCorrtction(double *data_out,double *data1,double *data2,int datanum)
{
	double sxy;
	int   i;
	int delay,j;

	for(delay = -(datanum)+ 1; delay < datanum; delay++)
	{
		//Calculate the numerator
		sxy = 0;
		for(i=0; i<datanum; i++)
		{
			j = i + delay;
			if((j < 0) || (j >= datanum))  //The series are no wrapped,so the value is ignored
				continue;
			else
				sxy += (data1[i] * data2[j]);
		}
		data_out[delay + datanum - 1] = sxy;
	}
	sxy = 0;
}

/*****************pointdetection*********************/
void GetDBLevel(unsigned char *level_out,unsigned int fs)
{
	unsigned int i;
    if(fs==48000)
    {
    	for(i=0;i<88;i++)
    	{
    		if(i<10)
    		{
    			level_out[i] = 9;
    		}
    		else if(i<23)
    		{
    			level_out[i] = 8;
    		}
    		else if(i<35)
    		{
    			level_out[i] = 7;
    		}
    		else if(i<47)
    		{
    			level_out[i] = 6;
    		}
    		else if(i<59)
    		{
    			level_out[i] = 5;
    		}
    		else if(i<71)
    		{
    			level_out[i] = 4;
    		}
    		else if(i<83)
    		{
    			level_out[i] = 3;
    		}
    		else
    		{
    			level_out[i] = 2;
    		}
    	}
    }
    else if(fs==16000)
    {
    	for(i=0;i<88;i++)
    	{
    		if(i<4)
    		{
    			level_out[i] = 8;
    		}
    		else if(i<17)
    		{
    			level_out[i] = 7;
    		}
    		else if(i<28)
    		{
    			level_out[i] = 6;
    		}
    		else if(i<40)
    		{
    			level_out[i] = 5;
    		}
    		else if(i<52)
    		{
    			level_out[i] = 4;
    		}
    		else if(i<64)
    		{
    			level_out[i] = 3;
    		}
    		else if(i<76)
    		{
    			level_out[i] = 2;
    		}
    		else
    		{
    			level_out[i] = 1;
    		}
    	}
    }
}

/*********生成88个单键基频*********/

void GetBaseFrequency(double *freq_out)
{
	unsigned int i;

	for(i=0;i<88;i++)
	{
		freq_out[i] = 27.5*pow((float) 2,(float) i/12);
	}
}

/****************FFT  function***************/
/* double *pr   input .real/output sqrt(.real.^2+.imag.^2)
 * double *pi   input .imag
 * int n        datalen
 * int k        2.^k = n;
 * double *fr   output .real
 * double *fi   output .imag
 */
void kfft(double *pr,double *pi,unsigned int n,int k)
{
	unsigned int it,m,is,i,j,nv;
	int l0;
    double p,q,s,vr,vi,poddr,poddi;
    double fr[n];
    double fi[n];
    for (it=0; it<=n-1; it++)  //将pr[0]和pi[0]循环赋值给fr[]和fi[]
    {
		m=it;
		is=0;
		for(i=0; i<=k-1; i++)
       {
			j=m/2;
			is=2*is+(m-2*j);
			m=j;
		}
       fr[it]=pr[is];
       fi[it]=pi[is];
    }
	pr[0]=1.0;
	pi[0]=0.0;
	p=6.283185306/(1.0*n);
	pr[1]=cos(p); //将w=e^-j2pi/n用欧拉公式表示
	pi[1]=-sin(p);

	for (i=2; i<=n-1; i++)  //计算pr[]
	{
		p=pr[i-1]*pr[1];
		q=pi[i-1]*pi[1];
		s=(pr[i-1]+pi[i-1])*(pr[1]+pi[1]);
		pr[i]=p-q; pi[i]=s-p-q;
	}
	for (it=0; it<=n-2; it=it+2)
	{
		vr=fr[it];
		vi=fi[it];
		fr[it]=vr+fr[it+1];
		fi[it]=vi+fi[it+1];
		fr[it+1]=vr-fr[it+1];
		fi[it+1]=vi-fi[it+1];
	}
	m=n/2;
	nv=2;
	for (l0=k-2; l0>=0; l0--) //蝴蝶操作
	{
		m=m/2;
		nv=2*nv;
		for (it=0; it<=(m-1)*nv; it=it+nv)
		{
			for (j=0; j<=(nv/2)-1; j++)
			{
				p=pr[m*j]*fr[it+j+nv/2];
				q=pi[m*j]*fi[it+j+nv/2];
				s=pr[m*j]+pi[m*j];
				s=s*(fr[it+j+nv/2]+fi[it+j+nv/2]);
				poddr=p-q;
				poddi=s-p-q;
				fr[it+j+nv/2]=fr[it+j]-poddr;
				fi[it+j+nv/2]=fi[it+j]-poddi;
				fr[it+j]=fr[it+j]+poddr;
				fi[it+j]=fi[it+j]+poddi;
			}
		}
	}
	for (i=0; i<=n-1; i++)
	{
		pr[i]=sqrt(fr[i]*fr[i]+fi[i]*fi[i]);  //幅值计算
	}
	return;
}

/***************小波分解*********************/
int  DWT(double *pSrcData,int srcLen,double *pDstCeof,int filterLen,double *Lo_D,double *Hi_D)
{
	if (srcLen < filterLen - 1)
	{
		exit(1);
	}
	int exLen = (srcLen + filterLen - 1) / 2;//对称拓延后系数的长度
	int k = 0;
	double tmp = 0.0;
	for (int i = 0; i < exLen; i++)
	{
		pDstCeof[i] = 0.0;
		pDstCeof[i + exLen] = 0.0;
		for (int j = 0; j < filterLen; j++)
		{
			k = 2 * i - j + 1;
			//信号边沿对称延拓
			if ((k<0) && (k >= -filterLen + 1))//左边沿拓延
				tmp = pSrcData[-k - 1];
			else if ((k >= 0) && (k <= srcLen - 1))//保持不变
				tmp = pSrcData[k];
			else if ((k>srcLen - 1) && (k <= (srcLen + filterLen - 2)))//右边沿拓延
				tmp = pSrcData[2 * srcLen - k - 1];
			else
				tmp = 0.0;
			pDstCeof[i] += Lo_D[j] * tmp;
			pDstCeof[i + exLen] += Hi_D[j] * tmp;
		}
	}
	return 2 * exLen;
}

/*************小波重构************************/
void  IDWT(double *pSrcCoef,int dstLen,double *pDstData,int filterLen,double *Lo_R,double *Hi_R)
{
	//pSrcCoef     源分解系数
	//dstLen       重构出来的系数的长度
	//pDstData     重构出来的系数
	//filterLen    重构滤波器长度
	//Lo_R         重构低通滤波器系数
	//Hi_R         重构高通滤波器系数
	int p = 0;
	int caLen = (dstLen + filterLen - 1) / 2;
	for (int i = 0; i < dstLen; i++)
	{
		pDstData[i] = 0.0;
		for (int j = 0; j < caLen; j++)
		{
			p = i - 2 * j + filterLen - 2;
			//信号重构
			if ((p >= 0) && (p<filterLen))
				pDstData[i] += Lo_R[p] * pSrcCoef[j] + Hi_R[p] * pSrcCoef[j + caLen];
		}
	}
}

/****************找极大值函数******************/
void findPeaks(double *src, int src_lenth,int distance, int *indMax, int *indMax_len)
{
	int sign[src_lenth];
	int max_index = 0;
	*indMax_len = 0;
	for (int i = 1; i<src_lenth; i++)
	{
		double diff;
		diff = src[i] - src[i - 1];
		if (diff>0)
			sign[i - 1] = 1;
		else if (diff<0)
			sign[i - 1] = -1;
		else
			sign[i - 1] = 0;
	}
	for (int j = 1; j<src_lenth - 1; j++)
	{
		double diff;
		diff = sign[j] - sign[j - 1];
		if (diff<0)
			indMax[max_index++] = j;
	}
	int flag_max_index[max_index];
	int idelete[max_index];
	int temp_max_index[max_index];
	int bigger = 0;
	double tempvalue = 0;
	int i, j, k;
	//波峰
	for (int i = 0; i < max_index; i++)
	{
		flag_max_index[i] = 0;
		idelete[i] = 0;
	}
	for (i = 0; i < max_index; i++)
	{
		tempvalue = -1;
		for (j = 0; j < max_index; j++)
		{
			if (!flag_max_index[j])
			{
				if (src[indMax[j]] > tempvalue)
				{
					bigger = j;
					tempvalue = src[indMax[j]];
				}
			}
		}
		flag_max_index[bigger] = 1;
		if (!idelete[bigger])
		{
			for (k = 0; k < max_index; k++)
			{
				idelete[k] |= (indMax[k] - distance <= indMax[bigger] && indMax[bigger] <= indMax[k] + distance);
			}
			idelete[bigger] = 0;
		}
	}
	for (i = 0, j = 0; i < max_index; i++)
	{
		if (!idelete[i])
			temp_max_index[j++] = indMax[i];
	}
	for (i = 0; i < max_index; i++)
	{
		if (i < j)
			indMax[i] = temp_max_index[i];
		else
			indMax[i] = 0;
	}
	max_index = j;
	*indMax_len = max_index;
}

/*****Recognize Note**************/
int RecognitionNote(double*Frequency,double *Data_in,int DataLen,unsigned int fs,char dblevel,char flag)
{
	int FilterLen = 10;    //daubechies waves（DB5）length of filter
	//DB5滤波器高、低通滤波系数
	double db5_Lo_D[10] = {0.003335725285002,-0.012580751999016,-0.006241490213012,0.077571493840065,-0.032244869585030,-0.242294887066190,0.138428145901103,0.724308528438574,0.603829269797473,0.160102397974125};
	double db5_Hi_D[10] = {-0.160102397974125,0.603829269797473,-0.724308528438574,0.138428145901103,0.242294887066190,-0.032244869585030,-0.077571493840065,-0.006241490213012,0.012580751999016,0.003335725285002};
	double db5_Lo_R[10] = {0.160102397974125,0.603829269797473,0.724308528438574,0.138428145901103,-0.242294887066190,-0.032244869585030,0.077571493840065,-0.006241490213012,-0.012580751999016,0.003335725285002};
	double db5_Hi_R[10] = {0.003335725285002,0.012580751999016,-0.006241490213012,-0.077571493840065,-0.032244869585030,0.242294887066190,0.138428145901103,-0.724308528438574,0.603829269797473,-0.160102397974125};

	double data_out[4096]={0};
	int CorrectInDataLen = 2048;        //In to Correct Data Point
	int CorrectOutDataLen = 4095;    //Out to Correct Data Point
	unsigned int Fft_DataLen=4096;                 //Point number of correct data

	int datalen1=0,datalen2=0,datalen3=0,datalen4=0,datalen5=0,datalen6=0,datalen7=0,datalen8=0;
	double wavedec1[2*1028];
	double wavedec2[1028],wavedec3[2*518],wavedec4[518],wavedec5[2*263],wavedec6[263],wavedec7[2*136],wavedec8[136],wavedec9[2*72];
	double wavedec10[72],wavedec11[2*40],wavedec12[40],wavedec13[2*24],wavedec14[24],wavedec15[2*16];
	double wavedec[2048];
	double wavedec0[2048]={0};
	int i,j;

	for(i=0;i<DataLen;i++)
	{
		wavedec[i] = 0;
	}

	datalen1 = (DataLen+10-1)/2;         //3076 points
	datalen2 = (datalen1+10-1)/2;                    //1542  points
	datalen3 = (datalen2+10-1)/2;                   //775    points
	datalen4 = (datalen3+10-1)/2;                   //392    points
	datalen5 = (datalen4+10-1)/2;                   //200    points
	datalen6 = (datalen5+10-1)/2;                   //104     points
	datalen7 = (datalen6+10-1)/2;                   //56      points
	datalen8 = (datalen7+10-1)/2;                   //32      points

	for(i=0;i<2*datalen1;i++)
	{
		wavedec1[i] = 0;
	}
	for(i=0;i<datalen1;i++)
	{
		wavedec2[i] = 0;
	}
	for(i=0;i<2*datalen2;i++)
	{
		wavedec3[i] = 0;
	}
	for(i=0;i<datalen2;i++)
	{
		wavedec4[i] = 0;
	}
	for(i=0;i<2*datalen3;i++)
	{
		wavedec5[i] = 0;
	}
	for(i=0;i<datalen3;i++)
	{
		wavedec6[i] = 0;
	}
	for(i=0;i<2*datalen4;i++)
	{
		wavedec7[i] = 0;
	}
	for(i=0;i<datalen4;i++)
	{
		wavedec8[i] = 0;
	}
	for(i=0;i<2*datalen5;i++)
	{
		wavedec9[i] = 0;
	}
	for(i=0;i<datalen5;i++)
	{
		wavedec10[i] = 0;
	}
	for(i=0;i<2*datalen6;i++)
	{
		wavedec11[i] = 0;
	}
	for(i=0;i<datalen6;i++)
	{
		wavedec12[i] = 0;
	}
	for(i=0;i<2*datalen7;i++)
	{
		wavedec13[i] = 0;
	}
	for(i=0;i<datalen7;i++)
	{
		wavedec14[i] = 0;
	}
	for(i=0;i<2*datalen8;i++)
	{
		wavedec15[i] = 0;
	}

	//Wavelet decomposition
	//first level
	DWT(Data_in,DataLen,wavedec1,FilterLen,db5_Lo_D,db5_Hi_D);
	for(j=0;j<datalen1;j++)
	{
		wavedec2[j] = wavedec1[j];
		wavedec1[datalen1+j] = 0;       //set last 2052 points to zero
	}
	if(dblevel>=2){
		//second level
		DWT(wavedec2,datalen1,wavedec3,FilterLen,db5_Lo_D,db5_Hi_D);
		for(j=0;j<datalen2;j++)
		{
			wavedec4[j] = wavedec3[j];
			wavedec3[datalen2+j] = 0;       ////set last 1030 points to zero
		}
	}
	if(dblevel>=3){
		//third level
		DWT(wavedec4,datalen2,wavedec5,FilterLen,db5_Lo_D,db5_Hi_D);
		for(j=0;j<datalen3;j++)
		{
			wavedec6[j] = wavedec5[j];
			wavedec5[datalen3+j] = 0;       ////set last 519 points to zero
		}
	}
	if(dblevel>=4){
		//forth level
		DWT(wavedec6,datalen3,wavedec7,FilterLen,db5_Lo_D,db5_Hi_D);
		for(j=0;j<datalen4;j++)
		{
			wavedec8[j] = wavedec7[j];
			wavedec7[datalen4+j] = 0;       ////set last 264 points to zero
		}
	}
	if(dblevel>=5){
		//fifth level
		DWT(wavedec8,datalen4,wavedec9,FilterLen,db5_Lo_D,db5_Hi_D);
		for(j=0;j<datalen5;j++)
		{
			wavedec10[j] = wavedec9[j];
			wavedec9[datalen5+j] = 0;       ////set last 200 points to zero
		}
	}
	if(dblevel>=6){
		//sixth level
		DWT(wavedec10,datalen5,wavedec11,FilterLen,db5_Lo_D,db5_Hi_D);
		for(j=0;j<datalen6;j++)
		{
			wavedec12[j] = wavedec11[j];
			wavedec11[datalen6+j] = 0;       ////set last 72 points to zero
		}
	}
	if(dblevel>=7){
		//seventh level
		DWT(wavedec12,datalen6,wavedec13,FilterLen,db5_Lo_D,db5_Hi_D);
		for(j=0;j<datalen7;j++)
		{
			wavedec14[j] = wavedec13[j];
			wavedec13[datalen7+j] = 0;       ////set last 40 points to zero
		}
	}
	if(dblevel>=8){
		//eighth level
		DWT(wavedec14,datalen7,wavedec15,FilterLen,db5_Lo_D,db5_Hi_D);
		for(j=0;j<datalen8;j++)
		{
			wavedec15[datalen8+j] = 0;       ////set last 24 points to zero
		}
	}

	//wave reconsitution
	if(dblevel>=8){
		//eighth level
		IDWT(wavedec15,datalen7,wavedec14,FilterLen,db5_Lo_R,db5_Hi_R);
		for(j=0;j<datalen7;j++)
		{
			wavedec13[j] = wavedec14[j];
			wavedec13[j+datalen7] = 0;
		}
	}
	if(dblevel>=7){
		//seventh level
		IDWT(wavedec13,datalen6,wavedec12,FilterLen,db5_Lo_R,db5_Hi_R);
		for(j=0;j<datalen6;j++)
		{
			wavedec11[j] = wavedec12[j];
			wavedec11[j+datalen6] = 0;
		}
	}
	if(dblevel>=6){
		//sixth level
		IDWT(wavedec11,datalen5,wavedec10,FilterLen,db5_Lo_R,db5_Hi_R);
		for(j=0;j<datalen5;j++)
		{
			wavedec9[j] = wavedec10[j];
			wavedec9[j+datalen5] = 0;
		}
	}
	if(dblevel>=5){
		//fifth level
		IDWT(wavedec9,datalen4,wavedec8,FilterLen,db5_Lo_R,db5_Hi_R);
		for(j=0;j<datalen4;j++)
		{
			wavedec7[j] = wavedec8[j];
			wavedec7[j+datalen4] = 0;
		}
	}
	if(dblevel>=4){
		//forth level
		IDWT(wavedec7,datalen3,wavedec6,FilterLen,db5_Lo_R,db5_Hi_R);
		for(j=0;j<datalen3;j++)
		{
			wavedec5[j] = wavedec6[j];
			wavedec5[j+datalen3] = 0;
		}
	}
	if(dblevel>=3){
		//third level
		IDWT(wavedec5,datalen2,wavedec4,FilterLen,db5_Lo_R,db5_Hi_R);
		for(j=0;j<datalen2;j++)
		{
			wavedec3[j] = wavedec4[j];
			wavedec3[j+datalen2] = 0;
		}
	}
	if(dblevel>=2){
		//second level
		IDWT(wavedec3,datalen1,wavedec2,FilterLen,db5_Lo_R,db5_Hi_R);
		for(j=0;j<datalen1;j++)
		{
			wavedec1[j] = wavedec2[j];
			wavedec1[datalen1+j] = 0;
		}
	}
	//first level
	IDWT(wavedec1,DataLen,wavedec,FilterLen,db5_Lo_R,db5_Hi_R);
	for(i=0;i<DataLen;i++)
	{
		wavedec0[i] = wavedec[i];
	}
	double dataout[CorrectOutDataLen];

	for(i=0;i<CorrectOutDataLen;i++)
	{
		dataout[i] = 0;
	}

	GetCorrtction(dataout,wavedec0,wavedec0,CorrectInDataLen);

	double data_imag[Fft_DataLen];

    for(i=0;i<CorrectOutDataLen;i++)
    {
    	data_out[i]=dataout[i];
    }

    for(i=0;i<Fft_DataLen;i++)
    {
        data_imag[i] = 0;
    }

    kfft(data_out,data_imag,Fft_DataLen,12);

	int data_lenth = 0;

	data_lenth = fs/(pow(2,dblevel+2));

	double data0[data_lenth];

	for(i=0;i<data_lenth;i++)
	{
		data0[i] = data_out[i];
	}

	int s1[data_lenth];         //location of peak
	double s2[data_lenth];            //peak of wave
	int maxlen = 0;
	double temp1 = 0;
	int temp2 = 0;
	int k,isSorted;

	for(i=0;i<data_lenth;i++)
	{
		s1[i] =0;
		s2[i] =0;
	}
	//find the peak of wave to s1
	findPeaks(data0,data_lenth,1,s1,&maxlen);
	//get the peak of wave to s2
	for(j=0;j<maxlen;j++)
	{
		s2[j] = data0[s1[j]];
	}

	//sorting the peaks of wave
	for(j=1; j<maxlen; j++)
	{
		isSorted = 1;
		for(k=0; k<maxlen-j; k++)
		{
			if(s2[k] > s2[k+1])
			{
				temp1 = s2[k];
				temp2 = s1[k];
				s2[k] = s2[k+1];
				s1[k] = s1[k+1];
				s2[k+1] = temp1;
				s1[k+1] = temp2;
				isSorted = 0;
			}
		}
		if(isSorted==1) break;
	}
	double s3[data_lenth];
	for(i=0;i<data_lenth;i++){
		s3[i] = s1[i] ;
	}

	if(maxlen<8)
	{
		for(i=0;i<maxlen;i++)
		{
			Frequency[i]=(s3[maxlen-1-i]+1)*fs/4096;
		}
	}
	else
	{
		for(i=0;i<8;i++)
		{
			Frequency[i]=(s3[maxlen-1-i]+1)*fs/4096;
		}
	}
	if(flag == 1){
		if(s2[maxlen-1]<=600){
		   return 1;
		}
		else{
			return 2;
		}
	}
	else{
		return 2;
	}
}

/*****definite parameter***********/
unsigned int Fs = 16000;                   //Samples (48000/44100/16000)
unsigned char DBnum[88];           //Daulbechies wave level
double basicfrequency[88];         //standard basic frequency of simple note
double PianoFrequency[88];         //save the samples of piano basic frequency (select from 3times samples)

unsigned int CalculateCount = 0;        //numbers of calculation
int Amp_winlen = 10;        //window length of amp to get slop
double Amp[10];             //512 points short energy array
double Slop=0;                //slop of 14 points short energy
int BeginTimes[2000];    //notes numbers of the song
int EndTimes[2000];       //voice end
double Processdata[2048];   //use to calculate the basic frequency
double Data[32768];         //process data point of benchmark
unsigned char VoiceSign=0;    //Sign of the Voice  0:noise; 1:get in voice; 2:process in voice
unsigned int VoiceCount=0;    //Count of voice
unsigned int BeginFlag=0;              //the begin of note
unsigned int NoteCount=0;                //Calculate note
unsigned int MissDetCount = 0;         //Missing Detection note
unsigned int SilenceCount = 0;             //Calculate noise
int ProcessDataLen = 2048;              //MaiMode 2 : Process data point
int ProcessDataNum=32768;          //MaiMode 1 : Process data point (Fs=48000:ProcessDataNum=24000;Fs=44100:ProcessDataNum=22050);
int **XmlIndex;//Index Array of Xml

int Practisesubsection[2] = {0};
int *Subsection;

int IndexLen = 0;

int ArrayIndex[20][8] = {0};        //Array data use to note location

int ErrorCount = 0;       //Number of note default detection
int RightModelCount = 0;
int Matchwindow=0;
int MissLocate=0;

/************Parameter initial************/
//void init(int **array0,int len)
//{
//     int i,j;
//     CalculateCount = 0;
//     Slop = 0;
//     VoiceSign = 0;
//     VoiceCount = 0;
//     BeginFlag = 0;
//     NoteCount = 0;
//     SilenceCount = 0;
//     RightModelCount = 0;
//	 RightModelCount = 0;
//	 MissLocate=0;
//	 Matchwindow=0;
//     for(i=0;i<Amp_winlen;i++)
//     {
//    	 Amp[i] = 0;
//     }
//     for(i=0;i<88;i++)
//     {
//    	 PianoFrequency[i] = 0;
//     }
//     for(i=0;i<2000;i++)
//     {
//    	 BeginTimes[i] = 0;
//     }
//     for(i=0;i<2000;i++)
//     {
//    	 EndTimes[i] = 0;
//     }
//     for(i=0;i<ProcessDataLen;i++)
//     {
//    	 Processdata[i] = 0;
//     }
//     for(i=0;i<ProcessDataNum;i++)
//     {
//    	 Data[i] = 0;
//     }
//     GetBaseFrequency(basicfrequency);
//     GetDBLevel(DBnum,Fs);
//
//     XmlIndex=(int **)malloc(sizeof(int *)*len);
//   	for(i=0;i<len;i++){
//   		XmlIndex[i] = (int *)malloc(sizeof(int )*10);
//   	}
//     for(i=0;i<len;i++){
//    	 for(j=0;j<10;j++){
//    		 XmlIndex[i][j] = array0[i][j];
//    	 }
//     }
//     IndexLen = len;
//}
void init(int **array0,int *array1,int *array2,int len1,int len2)
{
     int i,j;
     CalculateCount = 0;
     Slop = 0;
     VoiceSign = 0;
     VoiceCount = 0;
     BeginFlag = 0;
     SilenceCount = 0;
     RightModelCount = 0;
    RightModelCount = 0;
    MissLocate=0;
    Matchwindow=0;
     for(i=0;i<Amp_winlen;i++)
     {
      Amp[i] = 0;
     }
     for(i=0;i<88;i++)
     {
      PianoFrequency[i] = 0;
     }
     for(i=0;i<2000;i++)
     {
      BeginTimes[i] = 0;
     }
     for(i=0;i<2000;i++)
     {
      EndTimes[i] = 0;
     }
     for(i=0;i<ProcessDataLen;i++)
     {
      Processdata[i] = 0;
     }
     for(i=0;i<ProcessDataNum;i++)
     {
      Data[i] = 0;
     }
     GetBaseFrequency(basicfrequency);
     GetDBLevel(DBnum,Fs);
     XmlIndex=(int **)malloc(sizeof(int *)*len1);
    for(i=0;i<len1;i++){
    XmlIndex[i] = (int *)malloc(sizeof(int)*10);
    }
    for(i=0;i<len1;i++){
    for(j=0;j<10;j++){
    XmlIndex[i][j] = array0[i][j];
    }
    }
    Subsection=(int*)malloc(sizeof(int)*len2);
    for(i=0;i<len2;i++){
    Subsection[i] = array1[i];
    }
    Practisesubsection[0] = array2[0];
    Practisesubsection[1] = array2[1];
    IndexLen = 0;
    for(i=0;i<=array2[1];i++){
     IndexLen=IndexLen+Subsection[i];
    }
    NoteCount=0;
    if(array2[0]!=0){
      for(i=0;i<array2[0];i++){
       NoteCount = NoteCount+Subsection[i];
      }
    }
}


/******************Detection the Basic Frequency*************************/
//#ifndef _CLOCK_T_DEFINED
//typedef long clock_t;
//#define _CLOCK_T_DEFINED
//#endif

void  testcode(double *data_byte,int *ParameterOut,int datalength,int Modeflag)
{
	/*
	 * data_byte           1024byte of PCM-code
	 * pointnum            length(data_byte)/2  16bit PCM-code，2 byte mean one sample，data length = 512；
	 * mainmodesign        gather the simple note:0xAB; normal detection:0xCD
	 * secretarray         Confidential Information
	 */

	unsigned int PointNum = 256;    //number of sample data
	int Slop_Gate = 15;                   //threshold of slop
	double Frequency[8]={0};
	int PianoKeys[8]={0};
    int i,j,k;
    int zcr = 0;
    unsigned char MatchFlag = 0;     //Match successful, 0x03:match with n-1 code; 0x0C:match with n code;0x30:match with n+1 code;0xC0:match with n+2 code.
    char DetectionFlag = 0;
    char ErrorFlag = 0;
    char ParameterFlag = 0;
    char VoiceCountFlag=0;
    char PianokeyFlag = 0  ;
	int MetronFlag = 0;

            MatchFlag = 0;
			ErrorFlag = 0;
			for(i=0;i<8;i++)
			{
				Frequency[i] = 0;
			}
            for(i=0;i<8;i++){
            	PianoKeys[i] = 0;
            }

            if(Modeflag==2){                                   //Modeflag = 2 漏检模式
            	for(i=0;i<2048;i++){
            		Processdata[i] = data_byte[i];
            	}
				int db_level;
				int tempdata1 = 0;
				if(XmlIndex[NoteCount-2][0] == 0){
					tempdata1 = XmlIndex[NoteCount-2][6];
					if(tempdata1<=88){
						db_level = DBnum[tempdata1];
					}else{
						db_level = 2;
					}
					if(tempdata1>=68||tempdata1<=20){
						PianokeyFlag = 1;
					}else{
						PianokeyFlag = 0;
					}
				}else{
					tempdata1 = XmlIndex[NoteCount-2][1];
					if(tempdata1<=88){
						db_level = DBnum[tempdata1];
					}else{
						db_level = 2;
					}
					if(tempdata1>=68||tempdata1<=20){
						PianokeyFlag = 1;
					}else{
						PianokeyFlag = 0;
					}
				}
            	RecognitionNote(Frequency,Processdata,ProcessDataLen,Fs,db_level,PianokeyFlag);
				double tempdata=0;
				int zeroc = 0;
				for(i=0;i<8;i++){
					for(j=0;j<88;j++){
						tempdata = abs(Frequency[i] -basicfrequency[j])/basicfrequency[j];
						if(tempdata <= 0.02){
							PianoKeys[zeroc] = j+1;
							zeroc++;
							break;
						}
					}
				}
				if(zeroc>0){
					int Len1=0,Len2=0;
					int count1=0,count2=0;
					int tempdata2=0;
					//优先匹配当前序列
					Len1 = XmlIndex[NoteCount-2][0];
					Len2 = XmlIndex[NoteCount-2][5];
					tempdata2 = Len1+Len2;
					int tempdata0=0;
					for(i=0;i<tempdata2;i++){
						if(i<Len1){
							for(j=0;j<8;j++){
								if(PianoKeys[j]>=XmlIndex[NoteCount-2][i+1]){
									if(abs(PianoKeys[j] - XmlIndex[NoteCount-2][i+1])%12==0){
										count1++;
										break;
									}
								}
							}
						}else{
							for(j=0;j<8;j++){
								if(PianoKeys[j]>=XmlIndex[NoteCount-2][i+6-Len1]){
									if(abs(PianoKeys[j] - XmlIndex[NoteCount-2][i+6-Len1])%12==0){
										count2++;
										break;
									}
								}
							}
						}
					}
					tempdata0 = count1+count2;
					if(tempdata2>1){
						if(tempdata0>=tempdata2-1){
							DetectionFlag = 1;            //检测当前音正确
						}
						else{
							DetectionFlag = 0;           //检测当前音错误
						}
					}else{
						if(tempdata0>=1){
							DetectionFlag = 1;          //检测当前音正确
						}
						else{
							DetectionFlag = 0;          //检测当前音错误
						}
					}
				}
				else{
					DetectionFlag = 0;
				}
				ParameterOut[0] =  NoteCount-1;
				ParameterOut[2] = DetectionFlag;
				if(DetectionFlag == 0&&NoteCount>=2){
					ParameterOut[5] = BeginTimes[NoteCount-1];
					BeginTimes[NoteCount-2] = BeginTimes[NoteCount-1];
					BeginTimes[NoteCount-1] = 0;
					NoteCount--;
				}
            }
            else                               //Modeflag = 1 模式1正常检测
            {
            	CalculateCount ++ ;
				for (i=0;i<Amp_winlen-1;i++)
				{
					Amp[i]=Amp[i+1];
				}
				Amp[Amp_winlen-1] = shortenergy(data_byte,PointNum);
				Slop = GetSlop(Amp,Amp_winlen);
				if(VoiceSign==0)
				{
					if(Slop>Slop_Gate)      // confirm into the voice
					{
						VoiceSign = 1;
						SilenceCount = 0;     //set noise count zero
						VoiceCount ++;
						BeginFlag = CalculateCount;
						for(i=0;i<PointNum;i++)
						{
							Processdata[i] = data_byte[i];
						}
					}
					else
					{
						SilenceCount ++;
						VoiceSign = 0;
						VoiceCount = 0;
						if(SilenceCount>=950 && BeginFlag !=0)
						{
							EndTimes[NoteCount] = CalculateCount;
							BeginFlag = 0;
						}
						for(i=0;i<ProcessDataLen;i++)
						{
							Processdata[i] = 0;
						}
					}
				}
				else if(VoiceSign == 1)
				{
					if(Slop>Slop_Gate)
					{
						VoiceCount ++;
						SilenceCount = 0;
						for(i=0;i<PointNum;i++)
						{
							Processdata[(VoiceCount-1)*PointNum+i] = data_byte[i];
						}
					}
					else
					{
						VoiceSign = 0;
						VoiceCount = 0;
						SilenceCount ++;
						for(i=0;i<ProcessDataLen;i++)
						{
							Processdata[i] = 0;
						}
					}
					if(VoiceCount>=4)
					{
						VoiceSign = 2;
					}
				}
				else if(VoiceSign == 2)
				{
					VoiceCount ++;
					if(VoiceCount<=8)
					{
						for(i=0;i<PointNum;i++)
						{
							Processdata[(VoiceCount-1)*PointNum+i] = data_byte[i];
						}
					}
					else
					{
						for(i=0;i<ProcessDataLen-256;i++)
						{
							Processdata[i] = Processdata[i+256];
						}
						for(i=0;i<PointNum;i++)
						{
							Processdata[7*PointNum+i] = data_byte[i];
						}
					}
					if(NoteCount>=1){
						if(BeginFlag-BeginTimes[NoteCount-1]>8){
							VoiceCountFlag = 1;
						}else{
							VoiceCountFlag=0;
						}
					}
					else{
						VoiceCountFlag=1;
					}
					if(VoiceCount >= 8)                     //length of process data > 6144
					{
						if(VoiceCountFlag == 1){
							zcr = 0;
							double temp11[2048]={0};
							double temp12 = 0;
							for(i=0;i<2048;i++){
								temp11[i] = Processdata[i] - 0.08;
							}
							for(i=0;i<2047;i++){
								temp12 = temp11[i]*temp11[i+1];
								if(temp12<0){
									zcr++;
								}
							}
							if(zcr>50){
								//choose the daubechies level
								int db_level;
								NoteCount ++;         //note count +1
								if(NoteCount>IndexLen){
									NoteCount = 1;
                                    if(Practisesubsection[0]>1){
                                     for(i=0;i<Practisesubsection[0];i++){
                                      NoteCount = NoteCount+Subsection[i];
                                     }
                                    }
								}
								ParameterFlag = 1;
								//	Get db_level
								int tempdata1 = 0;
								if(XmlIndex[NoteCount-1][0] == 0){
									tempdata1 = XmlIndex[NoteCount-1][6];
									if(tempdata1<=88){
										db_level = DBnum[tempdata1];
									}else{
										db_level = 2;
									}
									if(tempdata1>=68||tempdata1<=20){
										PianokeyFlag = 1;
									}else{
										PianokeyFlag = 0;
									}
								}
								else{
									tempdata1 = XmlIndex[NoteCount-1][1];
									if(tempdata1<=88){
										db_level = DBnum[tempdata1];
									}else{
										db_level = 2;
									}
									if(tempdata1>=68||tempdata1<=20){
										PianokeyFlag = 1;
									}else{
										PianokeyFlag = 0;
									}
								}
								MetronFlag = RecognitionNote(Frequency,Processdata,ProcessDataLen,Fs,db_level,PianokeyFlag);
//								if(MetronFlag==1){
//									NoteCount--;
//								}
//								else{
									//Get the Piano Keys
									double tempdata=0;
									int zerocount = 0;
									for(i=0;i<8;i++){
										for(j=0;j<88;j++){
											tempdata = abs(Frequency[i] -basicfrequency[j])/basicfrequency[j];
											if(tempdata <= 0.02){
												PianoKeys[zerocount] = j+1;
												zerocount++;
												break;
											}
										}
									}
								   if(zerocount>0){
										int IndexCode[4][10]  = {0};
										//renew the piano keys array
										for(i=1;i<20;i++){
											for(j=0;j<8;j++){
												ArrayIndex[i-1][j] = ArrayIndex[i][j];
											}
										}
										for(i=0;i<8;i++){
											ArrayIndex[19][i] = PianoKeys[i];
										}
                                       
											for(i=0;i<10;i++){
												if(NoteCount<=1){
													IndexCode[2][i] = 0;
												}
												else{
													IndexCode[2][i] = XmlIndex[NoteCount-2][i];
												}
												IndexCode[0][i] = XmlIndex[NoteCount-1][i];
												if((NoteCount>=IndexLen-1)&&(NoteCount<IndexLen)){
													IndexCode[1][i] = XmlIndex[NoteCount][i];
													IndexCode[3][i] = 0;
												}
												else if(NoteCount>=IndexLen){
													IndexCode[1][i] = 0;
													IndexCode[3][i] = 0;
												}
												else{
													IndexCode[1][i] = XmlIndex[NoteCount][i];
													IndexCode[3][i] = XmlIndex[NoteCount+1][i];
												}
											}
											int Len1=0,Len2=0;
											int count1=0;
											int tempdata2=0;
											double matchwin=0;
											//优先匹配当前序列
											Len1 = IndexCode[0][0];
											Len2 = IndexCode[0][5];
											tempdata2 = Len1+Len2;
											for(i=0;i<tempdata2;i++){
													for(j=0;j<8;j++){
														if(i<Len1){
															if(PianoKeys[j]>=IndexCode[0][i+1]){
																if(abs(PianoKeys[j] - IndexCode[0][i+1])%12==0){
																	count1++;
																	if(tempdata2==1){
																		matchwin=1-(0.1*j);
																	}else{
																		matchwin = 0;
																	}
																	break;
																}
															}
													}else{
														if(PianoKeys[j]>=IndexCode[0][i+6-Len1]){
															if(abs(PianoKeys[j] - IndexCode[0][i+6-Len1])%12==0){
																count1++;
																if(tempdata2==1){
																	matchwin=1-(0.1*j);
																}else{
																	matchwin = 0;
																}
																break;
															}
														}
													}
												}
											}
                                       if(NoteCount==1){
                                           if(tempdata2>=3){
                                               if(count1>=tempdata2-1){
                                                       DetectionFlag = 1;            //检测当前音正确
                                                       ErrorCount = 0;
                                               }else{
                                                   DetectionFlag = 0;
                                               }
                                           }else{
                                               if(count1==tempdata2){
                                                   DetectionFlag = 1;            //检测当前音正确
                                                   ErrorCount = 0;
                                               }else{
                                                   DetectionFlag = 0;
                                               }
                                           }
                                       }
                                       else{
											if(tempdata2>1){
												if(count1>=tempdata2-1){
													DetectionFlag = 1;            //检测当前音正确
													ErrorCount = 0;
												}
												else{
													DetectionFlag = 0;           //检测当前音错误
												}
											}else{
												if(count1==tempdata2){
													DetectionFlag = 1;          //检测当前音正确
													ErrorCount = 0;
												}
												else{
													DetectionFlag = 0;          //检测当前音错误
												}
											}
                                       }
											matchwin=0;
                                            if(DetectionFlag == 0&&NoteCount>1){                                        //匹配当前音错误，则匹配相邻音符
												for(i=1;i<3;i++){
													if(NoteCount>=IndexLen){
														break;
													}
													count1=0;
													Len1 = IndexCode[i][0];
													Len2 = IndexCode[i][5];
													tempdata2 = Len1+Len2;
													for(j=0;j<tempdata2;j++){
														for(k=0;k<8;k++){
															if(j<Len1){
																if(PianoKeys[k]>=IndexCode[i][j+1]){
																	if(abs(PianoKeys[k] - IndexCode[i][j+1])%12==0){
																		count1++;
																		if(tempdata2==1){
																			matchwin=1-(0.1*j);
																		}else{
																			matchwin = 0;
																		}
																		break;
																	}
																}
															}
															else{
																if(PianoKeys[k]>=IndexCode[i][j+6-Len1]){
																	if(abs(PianoKeys[k] - IndexCode[i][j+6-Len1])%12==0){
																		count1++;
																		if(tempdata2==1){
																			matchwin=1-(0.1*j);
																		}else{
																			matchwin = 0;
																		}
																		break;
																	}
																}
															}
														}
													}
													if(tempdata2>1){
														if(count1>=tempdata2){
															if(i==1){
																MatchFlag = 2;                   //Missing Detection
																break;
															}else if(i==2){
																MatchFlag = 1;                   //Repetition Detection
																break;
															}
														}else{
															MatchFlag = 0;
														}
													}
													else{
														if(matchwin>=0.4){
															if(i==1){
																MatchFlag = 2;                   //Missing Detection
																break;
															}else if(i==2){
																MatchFlag = 1;                   //Repetition Detection
																break;
															}
														}
														else{
															MatchFlag = 0;
														}
													}
												}
												if(MatchFlag == 2){     //Detect the n+1th note ,Missing detect nth note
													NoteCount++;
													MissDetCount ++;
													ErrorFlag =2;                      //漏检
													DetectionFlag = 1;
													ErrorCount = 0;
												}
												else if(MatchFlag == 1){      //Detect the n-1 note
													NoteCount--;
													ErrorFlag =1;                    //重检
													DetectionFlag = 1;
													ErrorCount = 0;
												}
												else{
													ErrorCount++;
													DetectionFlag = 0;
													ErrorFlag = 4;                 //检错基频
												}
											}
                                        if(DetectionFlag==2){
                                            if(NoteCount>=2&&(BeginFlag-BeginTimes[NoteCount-2])<=10){
    //													   NoteCount--;
                                                BeginTimes[NoteCount-1] = BeginFlag;
                                            }
                                            else{
                                                BeginTimes[NoteCount-1] = BeginFlag;
                                            }
                                        }else{
                                            BeginTimes[NoteCount-1] = BeginFlag;
                                        }
                                        if(NoteCount==1&&DetectionFlag==0){
                                            NoteCount--;
                                        }
									}else{
										NoteCount --;             //Don't get the basic frequency;
										DetectionFlag=0;
									}
//								}
							}
							VoiceSign  = 0;
							VoiceCount = 0;
							SilenceCount = 0;
							for(i=0;i<ProcessDataLen;i++)
							{
								Processdata[i] = 0;
							}
						}else{
							VoiceSign  = 0;
							VoiceCount = 0;
							SilenceCount = 0;
							for(i=0;i<ProcessDataLen;i++)
							{
								Processdata[i] = 0;
							}
						}
				    }
				}
				if(ParameterFlag==1&&MetronFlag==2){
					     ParameterOut[0] =  NoteCount;
					     ParameterOut[2] = DetectionFlag;
					     ParameterOut[4] = ErrorFlag;
					     if(ErrorFlag == 2&&NoteCount>=3){                                   //若漏检，将begin当前值和前一个值帧数发回给前端
					    	 ParameterOut[5] = BeginTimes[NoteCount-3];
					    	 ParameterOut[6] = BeginTimes[NoteCount-1];
					     }
					     else if(ErrorFlag == 2&&NoteCount<3){
					    	 ParameterOut[5] = 0;
					    	 ParameterOut[6] = BeginTimes[NoteCount-1];
					     }
					     else{
					    	 if(NoteCount>=1){
					    		 ParameterOut[5] = BeginTimes[NoteCount-1];
					    	 }
					     }
				}
				ParameterFlag = 0;
            }
}
