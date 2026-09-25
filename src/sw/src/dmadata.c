
// Trigger and Send DMA Data: ADC, TbT, FA

#include <stdio.h>
#include <math.h>

#include <xparameters.h>

#include <FreeRTOS.h>
#include <lwip/sys.h>
#include <lwip/stats.h>
#include "xil_cache.h"

#include "local.h"
#include "zubpm.h"
#include "pl_regs.h"
#include "dmadata.h"

#include "xtime_l.h"





void dma_arm() {

	//u32 *adc_ptr, *tbt_ptr, *fa_ptr;
	u32 adclen;

	//xil_printf("Arming DMA...\r\n");
	//Disable the ADC,TbT,FA DMA logic (trig_logic.vhd)
	//xil_printf("   Disable DMA\r\n");
	//Xil_Out32(XPAR_M_AXI_BASEADDR + DMA_ADCENABLE_REG, 0);
	//Xil_Out32(XPAR_M_AXI_BASEADDR + DMA_TBTENABLE_REG, 0);
	//Xil_Out32(XPAR_M_AXI_BASEADDR + DMA_FAENABLE_REG, 0);


	//Read the DMA length registers, just so we can print them
	adclen = Xil_In32(XPAR_M_AXI_BASEADDR + DMA_ADCBURSTLEN_REG);
	//tbtlen = Xil_In32(XPAR_M_AXI_BASEADDR + DMA_TBTBURSTLEN_REG);
	//falen = Xil_In32(XPAR_M_AXI_BASEADDR + DMA_FABURSTLEN_REG);

	//xil_printf("   DMA ADC Length = %d\r\n",adclen);
	//xil_printf("   DMA TbT Length = %d\r\n",tbtlen);
	//xil_printf("   DMA FA Length = %d\r\n",falen);

	//clear the DMA memory, not necessary, already Invalidated it.
	//adc_ptr = (u32 *) ADC_DMA_DATA;
	//tbt_ptr = (u32 *) TBT_DMA_DATA;
	//fa_ptr  = (u32 *) FA_DMA_DATA;
	//for (i=0;i<10000000;i++)  adc_ptr[i] = 0;
	//for (i=0;i<10000000;i++)  tbt_ptr[i] = 0;
	//for (i=0;i<10000000;i++)  fa_ptr[i]  = 0;


	//reset the PL DMA FIFO
	Xil_Out32(XPAR_M_AXI_BASEADDR + DMA_FIFORST_REG, 1);
	Xil_Out32(XPAR_M_AXI_BASEADDR + DMA_FIFORST_REG, 0);

	//reset the AXI DMA Core
	Xil_Out32(XPAR_AXI_DMA_ADC_BASEADDR + S2MM_DMACR, 4);
	//Xil_Out32(XPAR_AXI_DMA_TBT_BASEADDR + S2MM_DMACR, 4);
	//Xil_Out32(XPAR_AXI_DMA_FA_BASEADDR + S2MM_DMACR, 4);

	//Start the S2MM channel with all interrupts masked
	Xil_Out32(XPAR_AXI_DMA_ADC_BASEADDR + S2MM_DMACR, 0xF001);
	//Xil_Out32(XPAR_AXI_DMA_TBT_BASEADDR + S2MM_DMACR, 0xF001);
	//Xil_Out32(XPAR_AXI_DMA_FA_BASEADDR + S2MM_DMACR, 0xF001);

	//Write the Destination Address for the ADC data
	Xil_Out32(XPAR_AXI_DMA_ADC_BASEADDR + S2MM_DA, ADC_DMA_DATA);
	//Xil_Out32(XPAR_AXI_DMA_TBT_BASEADDR + S2MM_DA, TBT_DMA_DATA);
	//Xil_Out32(XPAR_AXI_DMA_FA_BASEADDR + S2MM_DA, FA_DMA_DATA);


	//Write the S2MM transfer length (must be written last (PG021 p72)
    //length is in bytes, for adc: 4 adc channels * 2bytes/sample
	Xil_Out32(XPAR_AXI_DMA_ADC_BASEADDR + S2MM_LEN, (adclen+16) * 4 * 2);

	//length is in bytes, for TbT: 16 - 4 byte values
	//Xil_Out32(XPAR_AXI_DMA_TBT_BASEADDR + S2MM_LEN, (tbtlen) * 16 * 4);

	//length is in bytes, for FA: 10 - 4 byte values
	//Xil_Out32(XPAR_AXI_DMA_FA_BASEADDR + S2MM_LEN, (falen) * 10 * 4);


	//Enable the ADC,TbT,FA DMA logic (trig_logic.vhd)
	//DMA triggers are disabled until rising edge of ADC_ENABLE_REG
	//xil_printf("   Enabling DMA Triggers\r\n");
	//Xil_Out32(XPAR_M_AXI_BASEADDR + DMA_TBTENABLE_REG, 1);
	//Xil_Out32(XPAR_M_AXI_BASEADDR + DMA_FAENABLE_REG, 1);
	//Xil_Out32(XPAR_M_AXI_BASEADDR + DMA_ADCENABLE_REG, 1);


}

void read_ADC_dma(adcmsg_t *adcmsg, u32 nsamples)
{
    u32 i, regval;
    s16 cha, chb, chc, chd;
    u32 *adc_data = (u32 *)ADC_DMA_DATA;

    // Read samples from DMA buffer
    for (i = 0; i < nsamples; i++) {
        regval = *adc_data++;
        cha = (s16)((regval >> 16) & 0xFFFF);
        chb = (s16)(regval & 0xFFFF);

        regval = *adc_data++;
        chc = (s16)((regval >> 16) & 0xFFFF);
        chd = (s16)(regval & 0xFFFF);

        adcmsg[i].cha = cha;
        adcmsg[i].chb = chb;
        adcmsg[i].chc = chc;
        adcmsg[i].chd = chd;
    }

    // Debug print first 10
    /*
    for (i = 0; i < 10 && i < nsamples; i++) {
        xil_printf("Sample %lu: A=%d  B=%d  C=%d  D=%d\r\n",
                   (unsigned long)i,
                   ntohs(adcmsg[i].cha),
                   ntohs(adcmsg[i].chb),
                   ntohs(adcmsg[i].chc),
                   ntohs(adcmsg[i].chd));
    }
    */


}





void send_ADC_dma(adcmsg_t *adcmsg, u32 nsamples)
{
    u32 i;

    // Convert to network order
    for (i = 0; i < nsamples; i++) {
        adcmsg[i].cha = htons(adcmsg[i].cha);
        adcmsg[i].chb = htons(adcmsg[i].chb);
        adcmsg[i].chc = htons(adcmsg[i].chc);
        adcmsg[i].chd = htons(adcmsg[i].chd);
    }

    // Debug print first 10
    /*
    for (i = 0; i < 10 && i < nsamples; i++) {
        xil_printf("Sample %lu: A=%d  B=%d  C=%d  D=%d\r\n",
                   (unsigned long)i,
                   ntohs(adcmsg[i].cha),
                   ntohs(adcmsg[i].chb),
                   ntohs(adcmsg[i].chc),
                   ntohs(adcmsg[i].chd));
    }
    */

    // Send buffer (size = nsamples * sizeof(adcmsg_t))
    psc_send(the_server, 53, nsamples * sizeof(adcmsg_t), adcmsg);
}


static void scale_ADC_data(adcmsg_t *samples,
                           u32 nsamples,
                           const adc_gain_t *gain)
{

    for (u32 i = 0; i < nsamples; i++) {
        samples[i].cha =  samples[i].cha * gain->cha;
        samples[i].chb =  samples[i].chb * gain->chb;
        samples[i].chc =  samples[i].chc * gain->chc;
        samples[i].chd =  samples[i].chd * gain->chd;
    }

}






/*  Calculate the average ADC baseline.  */
static adc_baseline_t calculate_baselines(const adcmsg_t *adc,
                                          size_t first_sample,
                                          size_t sample_count)
{
    int64_t sum_a = 0;
    int64_t sum_b = 0;
    int64_t sum_c = 0;
    int64_t sum_d = 0;

    adc_baseline_t baseline = {0};

    if ((adc == NULL) || (sample_count == 0)) {
        return baseline;
    }

    for (size_t i = first_sample;
         i < first_sample + sample_count;
         i++) {
        sum_a += adc[i].cha;
        sum_b += adc[i].chb;
        sum_c += adc[i].chc;
        sum_d += adc[i].chd;
    }

    baseline.cha = (float)sum_a / (float)sample_count;
    baseline.chb = (float)sum_b / (float)sample_count;
    baseline.chc = (float)sum_c / (float)sample_count;
    baseline.chd = (float)sum_d / (float)sample_count;

    return baseline;
}



/*  Calculate the absolute sum of the ADC samples  */
static void sum_absolute_adc(const adcmsg_t *samples,
                             const adc_baseline_t *baseline,
                             u32 first_sample,
                             u32 sample_count,
                             u32 total_samples,
                             adc_sum_t *result)
{

    result->cha = 0.0f;
    result->chb = 0.0f;
    result->chc = 0.0f;
    result->chd = 0.0f;

    const u32 end_sample = first_sample + sample_count;

    for (u32 i = first_sample; i < end_sample; i++) {
    	//xil_printf("Sample: %d = %d\r\n",i,samples[i]);
        result->cha += fabsf((float)samples[i].cha - baseline->cha);
        result->chb += fabsf((float)samples[i].chb - baseline->chb);
        result->chc += fabsf((float)samples[i].chc - baseline->chc);
        result->chd += fabsf((float)samples[i].chd - baseline->chd);
    }


}



static s32 find_adc_signal_start(const adcmsg_t *adc,
                                 u32 nsamples,
                                 s16 threshold)
{
    for (u32 i = 0; i < nsamples; i++) {

        if ((abs(adc[i].cha) > threshold) ||
            (abs(adc[i].chb) > threshold) ||
            (abs(adc[i].chc) > threshold) ||
            (abs(adc[i].chd) > threshold)) {

            return (s32)i;
        }
    }

    return -1;      // no signal found
}







static void dmadata_push(void *unused)
{
    (void)unused;

    static struct {
       	u32 count;        // PSC Offset 0
        u32 evr_ts_ns;    // PSC Offset 4
       	u32 evr_ts_s;     // PSC Offset 8
       	u32 cha_mag;      // PSC Offset 12
       	u32 chb_mag;      // PSC Offset 16
       	u32 chc_mag;      // PSC Offset 20
       	u32 chd_mag;      // PSC Offset 24
       	u32 sum;          // PSC Offset 28
       	s32 xpos_nm;      // PSC Offset 32
       	s32 ypos_nm;      // PSC Offset 36
    } msg;


    static adcmsg_t adcmsg[ADC_DMA_MAX_LEN];
    adc_baseline_t baseline;
    adc_sum_t adc_sum;
    adc_gain_t adc_gain;
    u32 thresh, beamdly;
    s32 bba_x, bba_y;

    u32 adclen;
    u32 trignum = 0, prevtrignum = 0;

    float sum;
    u32 kx = 1;
    u32 ky = 1;
    float xpos, ypos;


    dma_arm();

    while (1) {
        vTaskDelay(pdMS_TO_TICKS(10));

        //trignum is incremented after DMA data is pushed to DDR
        trignum = Xil_In32(XPAR_M_AXI_BASEADDR + DMA_TRIGCNT_REG);

        if (trignum != prevtrignum) {
            xil_printf("Received DMA Trigger Number: %d \r\n",trignum);

            //read Kx, Ky (in nm)
            kx = Xil_In32(XPAR_M_AXI_BASEADDR + KX_REG);
            ky = Xil_In32(XPAR_M_AXI_BASEADDR + KY_REG);
            //xil_printf("Kx=%d  Ky=%d\r\n",kx,ky);

            //read the gain registers
            adc_gain.cha = (float)Xil_In32(XPAR_M_AXI_BASEADDR + CHA_GAIN_REG) / 32767.0;
            adc_gain.chb = (float)Xil_In32(XPAR_M_AXI_BASEADDR + CHB_GAIN_REG) / 32767.0;
            adc_gain.chc = (float)Xil_In32(XPAR_M_AXI_BASEADDR + CHC_GAIN_REG) / 32767.0;
            adc_gain.chd = (float)Xil_In32(XPAR_M_AXI_BASEADDR + CHD_GAIN_REG) / 32767.0;
            //printf("Gains: ChA=%f  ChB=%f  ChC=%f  ChD=%f\r\n",adc_gain.cha,adc_gain.chb,adc_gain.chc,adc_gain.chd);

            //Xil_Out32(XPAR_M_AXI_BASEADDR + DMA_ADCENABLE_REG, 0);
            //Xil_Out32(XPAR_M_AXI_BASEADDR + DMA_TBTENABLE_REG, 0);
            //Xil_Out32(XPAR_M_AXI_BASEADDR + DMA_FAENABLE_REG, 0);

            //xil_printf("\nTrig Num: %d\r\n", trignum);
            prevtrignum = trignum;

            // Invalidate caches to see fresh DMA data
            Xil_DCacheInvalidateRange(ADC_DMA_DATA, ADC_DMA_MAX_LEN * sizeof(adcmsg_t));


            // get the DMA lengths
           	adclen = Xil_In32(XPAR_M_AXI_BASEADDR + DMA_ADCBURSTLEN_REG);


            // Process DMA data into adcmsg array
            read_ADC_dma(adcmsg, adclen);
            thresh = Xil_In32(XPAR_M_AXI_BASEADDR + TRIGTOBEAM_THRESH_REG);
            xil_printf("Read Threshold Reg: %d\r\n",thresh);
            beamdly = Xil_In32(XPAR_M_AXI_BASEADDR + TRIGTOBEAM_DLY_REG);
            xil_printf("Beam Delay Reg: %d\r\n",beamdly);
            //scale beamdly to EVR clocks (it is in ADC clocks)
            beamdly = (int)((double)beamdly * EVR_CLOCK_FREQ_HZ / ADC_CLOCK_FREQ_HZ);
            xil_printf("Beam Delay (in EVR clocks): %d\r\n",beamdly);


            //s32 signal_start = find_adc_signal_start(adcmsg, adclen, thresh);
            //xil_printf("Signal start sample = %ld\r\n", (long)signal_start);
            //Xil_Out32(XPAR_M_AXI_BASEADDR + TRIGTOBEAM_DLY_REG, signal_start);

            scale_ADC_data(adcmsg, adclen, &adc_gain);


            baseline = calculate_baselines(adcmsg, 0, 50);
            //printf("Baselines: ChA=%.1f, ChB=%.1f, ChC=%.1f, ChD=%.1f\r\n",
            //		baseline.cha, baseline.chb, baseline.chc, baseline.chd);

            sum_absolute_adc(adcmsg, &baseline, 50, 250, adclen, &adc_sum);
            //printf("Sum      : ChA=%.1f, ChB=%.1f, ChC=%.1f, ChD=%.1f\r\n",
            //		adc_sum.cha, adc_sum.chb, adc_sum.chc, adc_sum.chd);

            //Calculate position
            sum = adc_sum.cha + adc_sum.chb + adc_sum.chc + adc_sum.chd;

            if (sum > 0.0f) {
                xpos = kx * (((adc_sum.cha + adc_sum.chd) -
                              (adc_sum.chb + adc_sum.chc)) / sum);

                ypos = ky * (((adc_sum.cha + adc_sum.chb) -
                              (adc_sum.chc + adc_sum.chd)) / sum);
            } else {
                xpos = 0.0f;
                ypos = 0.0f;
            }
            //printf("Xpos = %.3f    Ypos = %.3f\r\n\r\n",xpos, ypos);

            // Process DMA data into adcmsg array
            send_ADC_dma(adcmsg, adclen);


            //prepare and send the psc position data packet
            msg.count = htonl(Xil_In32(XPAR_M_AXI_BASEADDR + SA_TRIGNUM_REG));
            msg.evr_ts_ns = htonl(Xil_In32(XPAR_M_AXI_BASEADDR + EVR_TS_NS_REG));
            msg.evr_ts_s = htonl(Xil_In32(XPAR_M_AXI_BASEADDR + EVR_TS_S_REG));

            msg.cha_mag = htonl((u32)adc_sum.cha);
            msg.chb_mag = htonl((u32)adc_sum.chb);
            msg.chc_mag = htonl((u32)adc_sum.chc);
            msg.chd_mag = htonl((u32)adc_sum.chd);

            msg.sum = htonl((u32)sum);


            bba_x = Xil_In32(XPAR_M_AXI_BASEADDR + BBA_XOFF_REG);
            bba_y = Xil_In32(XPAR_M_AXI_BASEADDR + BBA_YOFF_REG);

            msg.xpos_nm = htonl((s32)(xpos - bba_x));
            msg.ypos_nm = htonl((s32)(ypos - bba_y));


            psc_send(the_server, 31, sizeof(msg), &msg);


            // Clear DMA Trigger Latch, allows for next trigger
            Xil_Out32(XPAR_M_AXI_BASEADDR + DMA_TXTOIOC_DONE_REG, 1);
            Xil_Out32(XPAR_M_AXI_BASEADDR + DMA_TXTOIOC_DONE_REG, 0);

            // Re-arm DMA for next trigger
            dma_arm();

        }
    }
}

void dmadata_setup(void)
{
    printf("INFO: Starting DMA Data daemon\n");
    sys_thread_new("dmadata", dmadata_push, NULL, THREAD_STACKSIZE, DEFAULT_THREAD_PRIO);
}

