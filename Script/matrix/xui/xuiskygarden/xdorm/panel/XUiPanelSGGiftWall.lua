local XUiPanelSGWall = require("XUi/XUiSkyGarden/XDorm/Panel/XUiPanelSGWall")

---@class XUiPanelSGGiftWall : XUiPanelSGWall
---@field _Control XSkyGardenDormControl
---@field Parent XUiSkyGardenDormPhotoWall
---@field _PanelOp XUiPanelSGGiftWallOp
local XUiPanelSGGiftWall = XClass(XUiPanelSGWall, "XUiPanelSGGiftWall")

local SgFurnitureType = XMVCA.XSkyGardenDorm.XSgFurnitureType
---@type X3CCommand
local X3C_CMD = CS.X3CCommand

function XUiPanelSGGiftWall:OnStart(areaType)
    self._AreaType = areaType
    self:InitUi()
    self:InitCb()
end

function XUiPanelSGGiftWall:Refresh()
    XUiPanelSGWall.Refresh(self)
end

function XUiPanelSGGiftWall:OnSelectTab(typeId, furnitureId)
    XUiPanelSGWall.OnSelectTab(self, typeId, furnitureId)
    if self._PanelOp then
        self._PanelOp:OnSelectTab(typeId, furnitureId)
    end
end

function XUiPanelSGGiftWall:OnSelectFurniture(id, cfgId, isCreate)
    local majorType = self._Control:GetFurnitureMajorType(cfgId)
    if majorType == SgFurnitureType.Gift then
        if not self._SelectPosIndex or self._SelectPosIndex < 0 then
            XUiManager.TipMsg(self._Control:GetSelectSlotFirstText())
            return
        end
        local data = self.Parent:GetContainerData()
        local isPut = false
        local putFurniture = data:GetFurniture(id)
        local isSameContainer = data:GetContainer():GetId() == id
        if putFurniture ~= nil or isSameContainer then
            isPut = true
        end
        if isPut then
            --放置了同一个家具在同一个槽位 || 同一个家具夹
            if (putFurniture and putFurniture:GetIndex() == self._SelectPosIndex) or isSameContainer then
                return
            end
            local confirmData = XMVCA.XBigWorldCommon:GetPopupConfirmData()
            local content = self._Control:GetGiftHasBeenPutText()
            confirmData:InitInfo(nil, content):InitToggleActive(false)
            confirmData:InitSureClick(nil, function()
                --移除原来的家具
                local index = self._PanelOp:TryGetSlotIndexById(id)
                self._PanelOp:RemoveFurniture(index, id, true)
                local func = self._CreateFunc[majorType]
                if func then
                    func(id, cfgId)
                end
            end)

            return XMVCA.XBigWorldUI:OpenConfirmPopup(confirmData)
        end
    end
    
    local func = self._CreateFunc[majorType]
    if func then
        func(id, cfgId)
    end
end

function XUiPanelSGGiftWall:InitUi()
    XUiPanelSGWall.InitUi(self)
    self._PanelTab = require("XUi/XUiSkyGarden/XDorm/Panel/XUiPanelSGWallTab").New(self.ScrollTitleTab, self, self._AreaType)
    self._PanelOp = require("XUi/XUiSkyGarden/XDorm/Panel/XUiPanelSGGiftWallOp").New(self.PanelWall, self, self._AreaType)
    
end

function XUiPanelSGGiftWall:InitCb()
    self._CreateFunc = {
        [SgFurnitureType.GiftShelf] = function(id, cfgId) self:OnCreateGiftShelf(id, cfgId) end,
        [SgFurnitureType.Gift] = function(id, cfgId) self:OnCreateGift(id, cfgId) end,
    }
end

function XUiPanelSGGiftWall:InitFurniture()
    local data = self.Parent:GetContainerData()
    local dict = data:GetFurnitureDict()
    ---@type XSgFurnitureData[]
    local list = {}
    for _, f in pairs(dict) do
        list[#list + 1] = f
    end
    table.sort(list, function(a, b)
        local indexA = a:GetIndex()
        local indexB = b:GetIndex()
        if indexA ~= indexB then
            return indexA < indexB
        end
        return a:GetId() < a:GetId()
    end)
    for i, f in pairs(list) do
        self._PanelOp:CreateFurniture(f:GetIndex(), f:GetId(), i == 1, false)
    end
end

function XUiPanelSGGiftWall:OnCreateGiftShelf(id, cfgId)
    local containerData = self.Parent:GetContainerData()
    if containerData:GetContainer():GetId() == id then
        return
    end
    
    local data =  XMVCA.X3CProxy:Send(X3C_CMD.CMD_DORMITORY_CHANGE_OR_CREATE_FRAME_WALL, {
        Id = self._Control:GetFurnitureSceneObjId(cfgId),
    })
    self._Control:UpdateGiftFightData(data)
    --更换容器
    containerData:ChangeContainer(id, cfgId)
    --通知战斗更换
    self._PanelOp:SwitchContainer()
    self.Parent:UpdateView()
end

function XUiPanelSGGiftWall:OnCreateGift(id, cfgId)
    if not self._SelectPosIndex or self._SelectPosIndex < 0 then
        XUiManager.TipMsg(self._Control:GetSelectSlotFirstText())
        return
    end
    local furnitureId = self._PanelOp:TryGetSlotFurnitureId(self._SelectPosIndex)
    --先移除掉
    if furnitureId and furnitureId > 0 then
        self._PanelOp:RemoveFurniture(self._SelectPosIndex, furnitureId, true)
    end
    local data =  XMVCA.X3CProxy:Send(X3C_CMD.CMD_DORMITORY_CREATE_FRAME_GOODS, {
        Id = id,
        SoId = self._Control:GetFurnitureSceneObjId(cfgId),
        PosIndex = self._SelectPosIndex,
    })
    self._Control:AddFightFurnitureData(id, data)
    self._PanelOp:CreateFurniture(self._SelectPosIndex, id, true, false)
end

function XUiPanelSGGiftWall:SetSelectIndex(index)
    self._SelectPosIndex = index
end

function XUiPanelSGGiftWall:GetSelectIndex()
    return self._SelectPosIndex
end

return XUiPanelSGGiftWall