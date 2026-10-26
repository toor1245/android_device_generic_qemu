/*
 * Copyright (c) 2026 Mykola Hohsadze
 *
 * Use of this source code is governed by a MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#ifndef __TA_AVB_H
#define __TA_AVB_H

#include <stdint.h>

int ta_avb_open(void);
void ta_avb_close(void);
int ta_avb_read_oem_unlock_allowed(uint32_t *oem_unlock_allowed);
int ta_avb_write_oem_unlock_allowed(uint32_t oem_unlock_allowed);

#endif /*__TA_AVB_H*/
