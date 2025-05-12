local XUiGridCollection = require("XUi/XUiMedal/XUiGridCollection")
local XUiGridCollectionWall = XClass(nil, "XUiGridCollectionWall")

local DefaultConditionDesc

function XUiGridCollectionWall:Ctor(ui, rootUi, openType)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.OpenType = openType
    XTool.InitUiObject(self)

    if self.OpenType == XCollectionWallConfigs.EnumWallGridOpenType.Overview then
        DefaultConditionDesc = self.TxtUnLockCondition.text
        self.BtnNoneState.CallBack = function() self:OnOverviewClick() end
        self.BtnLockState.CallBack = function() self:OnOverviewClick() end
        self.BtnNormalState.CallBack = function() self:OnOverviewClick() end
    elseif self.OpenType == XCollectionWallConfigs.EnumWallGridOpenType.Setting then
        self.BtnChoice.CallBack = function() self:OnSettingToggleClick() end
        self.BtnPanelWall.CallBack = function() self:BtnPanelWallClick() end
    end
    self.Resource = nil
end

---
--- 'wallData'的结构为XCollectionWall数据实体
function XUiGridCollectionWall:UpdateGrid(wallData)
    self.WallData = wallData

    if self.OpenType == XCollectionWallConfigs.EnumWallGridOpenType.Overview then
        -- 总览界面调用
        self.BtnNormalState.gameObject:SetActiveEx(false)
        self.BtnNoneState.gameObject:SetActiveEx(false)
        self.BtnLockState.gameObject:SetActiveEx(false)
        local state = wallData:GetState()

        if state == XCollectionWallConfigs.EnumWallState.Normal then
            -- 正常
            self.BtnNormalState.gameObject:SetActiveEx(true)
            self:SetImg()
            self.TxtWallName.text = wallData:GetName()
        elseif state == XCollectionWallConfigs.EnumWallState.None then
            -- 空白
            self.BtnNoneState.gameObject:SetActiveEx(true)
        else
            --未解锁
            self.BtnLockState.gameObject:SetActiveEx(true)
            local conditionId = wallData:GetCondition()
            local conditionDesc = XConditionManager.GetConditionDescById(conditionId)
            self.TxtUnLockCondition.text = conditionDesc or DefaultConditionDesc
        end

    elseif self.OpenType == XCollectionWallConfigs.EnumWallGridOpenType.Setting then
        -- 设置界面调用
        self:SetImg()
        self.TxtWallName.text = wallData:GetName()
        self.BtnChoice:SetButtonState(wallData:GetIsShow()
                and XUiButtonState.Select
                or XUiButtonState.Normal)
    else
        XLog.Error("XUiGridCollectionWall:UpdateGrid函数错误：没有设置OpenType")
    end
end

function XUiGridCollectionWall:SetImg()
    self.WallData:GetWallPicture(function(texture)
        local result = texture

        if not result then
            self.ImgTemplate:SetRawImage(CS.XGame.ClientConfig:GetString("CollectionWallDefaultIcon"))
        else
            self.ImgTemplate.texture = texture
        end
    end)
end

function XUiGridCollectionWall:OnRecycle()
    local defaultIconPath = CS.XGame.ClientConfig:GetString("CollectionWallDefaultIcon")
    self.ImgTemplate:SetSprite(defaultIconPath)
    if self.Resource then
        CS.XResourceManager.Unload(self.Resource)
        self.Resource = nil
    end
end

---
--- 总览界面(XUiCollectionWall)调用的点击函数
function XUiGridCollectionWall:OnOverviewClick()
    local state = self.WallData:GetState()

    if state == XCollectionWallConfigs.EnumWallState.Normal
            or state == XCollectionWallConfigs.EnumWallState.None then
        XLuaUiManager.Open("UiCollectionWallEdit", self.WallData)
    else
        XUiManager.TipMsg(self.TxtUnLockCondition.text)
    end
end

function XUiGridCollectionWall:OnSettingToggleClick()
    self.RootUi:ChangeCurShowSetting(self.WallData:GetId(), self.BtnChoice.ButtonState == CS.UiButtonState.Select)
end

function XUiGridCollectionWall:BtnPanelWallClick()
    if self.BtnChoice.ButtonState == CS.UiButtonState.Select then
        self.BtnChoice:SetButtonState(CS.UiButtonState.Normal)
    else
        self.BtnChoice:SetButtonState(CS.UiButtonState.Select)
    end
    self:OnSettingToggleClick()
end

---
--- 父UI调用，设置当前格子是否被选中
function XUiGridCollectionWall:SetIsSelect(isSelect)
    if isSelect then
        self.BtnChoice:SetButtonState(CS.UiButtonState.Select)
    else
        self.BtnChoice:SetButtonState(CS.UiButtonState.Normal)
    end

    self:OnSettingToggleClick()
end


return XUiGridCollectionWall