local XBigWorldAgency = require("XModule/XBigWorld/XBigWorldAgency")

---@class XSkyGardenAgency : XBigWorldAgency
---@field private _Model XSkyGardenModel
local XSkyGardenAgency = XClass(XBigWorldAgency, "XSkyGardenAgency")

---@type X3CCommand
local X3C_CMD = CS.X3CCommand

function XSkyGardenAgency:OnInit()
    XBigWorldAgency.OnInit(self)
    self._ModuleList = {
        ModuleId.XSkyGardenCafe,
        ModuleId.XSkyGardenShoppingStreet,
        ModuleId.XSkyGardenDorm,
        
    }
end

function XSkyGardenAgency:OnEnterFight()
    XMVCA.XSkyGardenCafe:RequestActivityData()
end

function XSkyGardenAgency:OnInitX3C()
    local register = function(cmd, func, obj)
        XMVCA.X3CProxy:RegisterHandler(cmd, func, obj)
    end
    
    -- todo remove check 临时测试
    if X3C_CMD.CMD_SHOPSTREET_REQUEST_GAMEPLAY_DATA then
        register(X3C_CMD.CMD_SHOPSTREET_REQUEST_GAMEPLAY_DATA, XMVCA.XSkyGardenShoppingStreet.X3CSgRequestData, XMVCA.XSkyGardenShoppingStreet)
    end
    if X3C_CMD.CMD_SHOPSTREET_CUSTOMER_FINISH_TASK then
        register(X3C_CMD.CMD_SHOPSTREET_CUSTOMER_FINISH_TASK, XMVCA.XSkyGardenShoppingStreet.X3CSgCustomerFinishTask, XMVCA.XSkyGardenShoppingStreet)
    end


    --宿舍
    register(X3C_CMD.CMD_DORMITORY_GET_GAMEPLAY_DATA, XMVCA.XSkyGardenDorm.OnFightGetGamePlayData, XMVCA.XSkyGardenDorm)
    register(X3C_CMD.CMD_DORMITORY_PUSH_SPACE_DATA, XMVCA.XSkyGardenDorm.OnFightPushData, XMVCA.XSkyGardenDorm)
    register(X3C_CMD.CMD_DORMITORY_OPERATE_PHOTO_WALL, XMVCA.XSkyGardenDorm.OpenPhotoWall, XMVCA.XSkyGardenDorm)
    register(X3C_CMD.CMD_DORMITORY_OPERATE_FRAME_WALL, XMVCA.XSkyGardenDorm.OpenGiftWall, XMVCA.XSkyGardenDorm)
    register(X3C_CMD.CMD_DORMITORY_CHANGE_DORMITORY_SKIN, XMVCA.XSkyGardenDorm.OpenFashion, XMVCA.XSkyGardenDorm)
end

function XSkyGardenAgency:OnExit()
    XMVCA.XSkyGardenCafe:Reset()
end

function XSkyGardenAgency:OnRegisterMVCA()
end

function XSkyGardenAgency:OnUnRegisterMVCA()
end

return XSkyGardenAgency