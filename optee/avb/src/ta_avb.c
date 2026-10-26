/*
 * Copyright (c) 2026 Mykola Hohsadze
 *
 * Use of this source code is governed by a MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include <stdbool.h>
#include <string.h>

#include <tee_client_api.h>
#include <ta_avb.h>

/* Must match optee_os/ta/avb/include/ta_avb.h */
#define TA_AVB_UUID { 0x023f8f1a, 0x292a, 0x432b, \
		      { 0x8f, 0xc4, 0xde, 0x84, 0x71, 0x35, 0x80, 0x67 } }

#define TA_AVB_CMD_READ_OEM_UNLOCK_ALLOWED	7
#define TA_AVB_CMD_WRITE_OEM_UNLOCK_ALLOWED	8

static const TEEC_UUID ta_avb_uuid = TA_AVB_UUID;
static TEEC_Context ctx;
static TEEC_Session sess;
static bool opened;

int ta_avb_open(void)
{
    if (TEEC_InitializeContext(NULL, &ctx) != TEEC_SUCCESS)
        return -1;

    if (TEEC_OpenSession(&ctx, &sess, &ta_avb_uuid, TEEC_LOGIN_PUBLIC,
                         NULL, NULL, NULL) != TEEC_SUCCESS) {
        TEEC_FinalizeContext(&ctx);
        return -1;
    }

    opened = true;
    return 0;
}

void ta_avb_close(void)
{
    if (!opened)
        return;

    TEEC_CloseSession(&sess);
    TEEC_FinalizeContext(&ctx);
    opened = false;
}

int ta_avb_read_oem_unlock_allowed(uint32_t *oem_unlock_allowed)
{
    TEEC_Operation op;
    uint32_t ret_origin;

    memset(&op, 0, sizeof(op));
    op.paramTypes = TEEC_PARAM_TYPES(TEEC_VALUE_OUTPUT, TEEC_NONE,
                                     TEEC_NONE, TEEC_NONE);

    if (TEEC_InvokeCommand(&sess, TA_AVB_CMD_READ_OEM_UNLOCK_ALLOWED, &op,
                           &ret_origin) != TEEC_SUCCESS)
        return -1;

    *oem_unlock_allowed = op.params[0].value.a;
    return 0;
}

int ta_avb_write_oem_unlock_allowed(uint32_t oem_unlock_allowed)
{
    TEEC_Operation op;
    uint32_t ret_origin;

    memset(&op, 0, sizeof(op));
    op.paramTypes = TEEC_PARAM_TYPES(TEEC_VALUE_INPUT, TEEC_NONE,
                                     TEEC_NONE, TEEC_NONE);
    op.params[0].value.a = oem_unlock_allowed;

    if (TEEC_InvokeCommand(&sess, TA_AVB_CMD_WRITE_OEM_UNLOCK_ALLOWED, &op,
                           &ret_origin) != TEEC_SUCCESS)
        return -1;

    return 0;
}
