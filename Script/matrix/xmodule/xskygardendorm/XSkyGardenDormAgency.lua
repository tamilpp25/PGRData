local XBigWorldActivityAgency = require("XModule/XBase/XBigWorldActivityAgency")

---@class XSkyGardenDormAgency : XBigWorldActivityAgency
---@field private _Model XSkyGardenDormModel
---@field private _Manager XDormitory.XDormManager
local XSkyGardenDormAgency = XClass(XBigWorldActivityAgency, "XSkyGardenDormAgency")

---@type X3CCommand
local X3C_CMD = CS.X3CCommand

function XSkyGardenDormAgency:OnInit()
    self.XSgDormAreaType = {
        --照片墙
        Wall = 1,
        --手办架
        GiftShelf = 2
    }

    self.XSgFurnitureType = {
        -- 装饰品
        Decoration = 1,

        -- 照片
        Photo = 2,

        -- 底板
        DecorationBoard = 3,

        -- 摆件
        Gift = 4,

        -- 摆件架
        GiftShelf = 5
    }

    self.CameraDuration = 0.5
    -- float -> long
    self.Ratio = 1000000
end

function XSkyGardenDormAgency:InitRpc()
    XRpc.NotifySgDormData = handler(self, self.NotifySgDormData)
    XRpc.NotifySgDormFurnitureAdd = handler(self, self.NotifySgDormFurnitureAdd)
    XRpc.NotifySgDormFashionAdd = handler(self, self.NotifySgDormFashionAdd)
    XRpc.NotifySgDormCurLayout = handler(self, self.NotifySgDormCurLayout)
end

function XSkyGardenDormAgency:InitEvent()
end

--- 家具墙
---@param wallType number
function XSkyGardenDormAgency:OpenFurnitureWall(wallType)
    if not self._TryRemoveBlackCb then
        self._TryRemoveBlackCb = function()
            XMVCA.XBigWorldLoading.CloseBlackMaskLoading()
        end
    end
    XMVCA.XBigWorldUI:OpenWithCallback("UiSkyGardenDormPhotoWall", self._TryRemoveBlackCb, wallType)
end

function XSkyGardenDormAgency:OpenPhotoWall()
    --黑屏
    XMVCA.XBigWorldLoading:OpenBlackMaskLoading(function()
        --隐藏指挥官
        XMVCA.XBigWorldGamePlay:SetCurNpcAndAssistActive(false, false)
        --推进相机
        XMVCA.XBigWorldGamePlay:ActivateVCamera("UiSkyGardenDormCameraPhotoWall", self.CameraDuration)
        --修改相机投影方式
        XMVCA.XBigWorldGamePlay:SetCameraProjection(true)
        --打开界面
        XScheduleManager.ScheduleOnce(function()
            self:OpenFurnitureWall(self.XSgDormAreaType.Wall)
        end, self.CameraDuration * 1000 + 20)
    end)
end

function XSkyGardenDormAgency:OpenGiftWall()
    --黑屏
    XMVCA.XBigWorldLoading:OpenBlackMaskLoading(function()
        --隐藏指挥官
        XMVCA.XBigWorldGamePlay:SetCurNpcAndAssistActive(false, false)
        --推进相机
        XMVCA.XBigWorldGamePlay:ActivateVCamera("UiSkyGardenDormCameraFrame", self.CameraDuration)
        --修改相机投影方式
        XMVCA.XBigWorldGamePlay:SetCameraProjection(true)
        --打开界面
        XScheduleManager.ScheduleOnce(function()
            self:OpenFurnitureWall(self.XSgDormAreaType.GiftShelf)
        end, self.CameraDuration * 1000 + 20)
    end)
end

function XSkyGardenDormAgency:OpenFashion()
    XMVCA.XBigWorldGamePlay:SetCurNpcAndAssistActive(false, false)
    XMVCA.XBigWorldUI:Open("UiSkyGardenDormCoating")
    XMVCA.XBigWorldGamePlay:ActivateVCamera("UiSkyGardenDormCameraChangeSkin", self.CameraDuration)
end

function XSkyGardenDormAgency:OnEnterLevel()
    CS.XDormitory.XDormManager.Init()
    self._Manager = CS.XDormitory.XDormManager.Instance
end

function XSkyGardenDormAgency:OnLeaveLevel()
    self._Manager:Destroy()
    self._Manager = nil
end

function XSkyGardenDormAgency:GetManager()
    if not self._Manager then
        XLog.Warning("管理器已经被回收，请勿调用！！！")
        return
    end
    return self._Manager
end

function XSkyGardenDormAgency:OnFightGetGamePlayData()
    local photos, adorns, gifts = self._Model:GetFightInitData(true, true)
    return {
        DormitorySkinId = self._Model:GetFashionSkinId(self._Model:GetDormData():GetCurFashionId()),
        PhotoWallId = self._Model:GetFurnitureSceneObjId(self._Model:GetLayoutContainer(self.XSgDormAreaType.Wall):GetCfgId()),
        FrameWallId = self._Model:GetFurnitureSceneObjId(self._Model:GetLayoutContainer(self.XSgDormAreaType.GiftShelf):GetCfgId()),
        Photos = photos,
        PhotoAdorns = adorns,
        FrameGoods = gifts
    }
end

function XSkyGardenDormAgency:OnFightPushData(data)
    self._Model:RemoveAllFightFurnitureData()
    self._Model:GetWallFightData():UpdateData(data.PhotoWallData.Transform)
    local giftData = data.FrameWallData
    self._Model:GetGiftShelfFightData():UpdateData(giftData.Transform, giftData.FrameGridSizeList)
    self._Model:UpdateFightFurnitureData(data.PhotosData)
    self._Model:UpdateFightFurnitureData(data.PhotoAdornsData)
    self._Model:UpdateFightFurnitureData(data.FrameGoodsData)
end

function XSkyGardenDormAgency:NotifySgDormData(data)
    self._Model:NotifySgDormData(data)
end

function XSkyGardenDormAgency:NotifySgDormFurnitureAdd(data)
    self._Model:NotifySgDormFurnitureAdd(data)
end

function XSkyGardenDormAgency:NotifySgDormFashionAdd(data)
    self._Model:NotifySgDormFashionAdd(data)
end

function XSkyGardenDormAgency:NotifySgDormCurLayout(data)
    self._Model:NotifySgDormCurLayout(data)
end

return XSkyGardenDormAgency