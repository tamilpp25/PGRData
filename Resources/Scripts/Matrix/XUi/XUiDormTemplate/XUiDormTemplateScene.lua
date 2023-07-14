local XUiDormTemplateScene = XLuaUiManager.Register(XLuaUi, "UiDormTemplateScene")
local XUiPanelFunitureList = require("XUi/XUiDormTemplate/XUiPanelFunitureList")
local XUiPanelSave = require("XUi/XUiDormTemplate/XUiPanelSave")
local XUiPanelEncoding = require("XUi/XUiDormTemplate/XUiPanelEncoding")

function XUiDormTemplateScene:OnAwake()
    self.IsHide = false
    self.BtnShow.gameObject:SetActiveEx(self.IsHide)
    self:AddListener()
end

function XUiDormTemplateScene:OnStart(dormitoryId, roomDataType, displaytype)
    XLuaUiManager.Close("UiLoading")
    self.FunitureListPanel = XUiPanelFunitureList.New(self.PanelFurnitureList, self)
    self.SavePanel = XUiPanelSave.New(self.PanelSave, self)
    self.EncodingPanel = XUiPanelEncoding.New(self.PanelEncoding, self)
    self:Refresh(dormitoryId, roomDataType, displaytype)
end

function XUiDormTemplateScene:Refresh(dormitoryId, roomDataType, displaytype)
    local roomType = roomDataType
    if roomDataType == XDormConfig.DormDataType.CollectNone then
        roomType = XDormConfig.DormDataType.Template
    end

    self.OldRoomDataType = roomDataType
    self.HomeRoomData = XDataCenter.DormManager.GetRoomDataByRoomId(dormitoryId, roomType)
    self.RoomDataType = self.HomeRoomData:GetRoomDataType()
    self.Displaytype = displaytype
    self.RoomId = self.HomeRoomData:GetRoomId()

    self:SetCollectNoneSence(dormitoryId, roomDataType)
    self:SetBtnStatus()
end

function XUiDormTemplateScene:AddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnHide, self.OnBtnHideOrShowClick)
    self:RegisterClickEvent(self.BtnShow, self.OnBtnHideOrShowClick)
    self:RegisterClickEvent(self.BtnShare, self.OnBtnShareClick)
    self:RegisterClickEvent(self.BtnDown, self.OnBtnDownClick)
    self:RegisterClickEvent(self.BtnSet, self.OnBtnSetClick)
    self:RegisterClickEvent(self.BtnSave, self.OnBtnSaveClick)
    self:RegisterClickEvent(self.BtnFurnitureList, self.OnBtnFurnitureListClick)
end

function XUiDormTemplateScene:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiDormTemplateScene:OnBtnBackClick()
    -- 退出模板场景
    if self.RoomDataType == XDormConfig.DormDataType.Template then
        if self.OldRoomDataType == XDormConfig.DormDataType.CollectNone then
            local titletext = CS.XTextManager.GetText("TipTitle")
            local contenttext = CS.XTextManager.GetText("DormTemplateNoneTip")

            XUiManager.DialogTip(titletext, contenttext, XUiManager.DialogType.Normal, function()
                self:BackToDormMain()
                self:Close()
            end, function()
                self:OnBtnSaveClick()
            end)
        else
            self:BackToDormMain()
        end
    elseif self.RoomDataType == XDormConfig.DormDataType.Collect then
        self:BackToDormMain()
    elseif self.RoomDataType == XDormConfig.DormDataType.Provisional then
        local lastProvisionalRoom = XDataCenter.DormManager.GetLastDormProvisionalData()
        if lastProvisionalRoom then
            local lastRoomId = lastProvisionalRoom:GetRoomId()
            XDataCenter.DormManager.EnterTeamplateDormitory(lastRoomId, XDormConfig.DormDataType.Provisional)
        else
            self:BackToDormMain()
        end
    end

    self:Close()
end

function XUiDormTemplateScene:BackToDormMain()
    XHomeDormManager.SetSelectedRoom(self.RoomId, false, true)
    XHomeSceneManager.ChangeBackToOverView()
    XHomeSceneManager.SetGlobalIllumSO(CS.XGame.ClientConfig:GetString("HomeSceneSoAssetUrl"))
end

-- 隐藏UI
function XUiDormTemplateScene:OnBtnHideOrShowClick()
    self.IsHide = not self.IsHide
    --self.BtnShare.gameObject:SetActiveEx(not self.IsHide)
    --self.BtnDown.gameObject:SetActiveEx(not self.IsHide)
    self.BtnShare.gameObject:SetActiveEx(false)--海外特供屏蔽宿舍分享按钮
    self.BtnDown.gameObject:SetActiveEx(false)

    self.BtnSet.gameObject:SetActiveEx(not self.IsHide)
    self.BtnSave.gameObject:SetActiveEx(not self.IsHide)
    self.BtnBack.gameObject:SetActiveEx(not self.IsHide)
    self.BtnFurnitureList.gameObject:SetActiveEx(not self.IsHide)
    self.BtnHide.gameObject:SetActiveEx(not self.IsHide)
    self.BtnShow.gameObject:SetActiveEx(self.IsHide)

    if not self.IsHide then
        self:SetBtnStatus()
    end
end

-- 分享场景
function XUiDormTemplateScene:OnBtnShareClick()
    local furnitureList = {}
    local furnitureDatas = self.HomeRoomData:GetFurnitureDic()

    for _, v in pairs(furnitureDatas) do
        local temData = {}
        temData.ConfigId = v.ConfigId
        temData.X = v.GridX
        temData.Y = v.GridY
        temData.Angle = v.RotateAngle
        table.insert(furnitureList, temData)
    end

    XDataCenter.DormManager.RequestDormSnapshotLayout(furnitureList, function(shareId)
        self.HomeRoomData:SetShareId(shareId)
        XHomeSceneManager.EnterShare(self.HomeRoomData)
    end)
end

-- 导入场景
function XUiDormTemplateScene:OnBtnDownClick()
    self:PlayAnimation("EncodingAnimEnable")
    self.EncodingPanel:Open()
end

-- 设置场景
function XUiDormTemplateScene:OnBtnSetClick()
    XLuaUiManager.Open("UiFurnitureReform", self.RoomId, self.RoomDataType)
end

-- 打开保存到收藏
function XUiDormTemplateScene:OnBtnSaveClick()
    self:PlayAnimation("SaveAnimEnable")
    self.SavePanel:Open(self.HomeRoomData)
end

-- 家具列表
function XUiDormTemplateScene:OnBtnFurnitureListClick()
    self:PlayAnimation("FurnitureListAnimEnable")
    self.FunitureListPanel:Open(self.HomeRoomData)
end

function XUiDormTemplateScene:SetCollectNoneSence(dormitoryId, roomDataType)
    local isCollectNone = roomDataType == XDormConfig.DormDataType.CollectNone
    if not isCollectNone then
        return
    end

    if XDataCenter.FurnitureManager.CheckCollectNoneFurnitrue(dormitoryId) then
        return
    end

    -- 处理空收藏场景
    local roomData = XHomeRoomData.New(dormitoryId)
    local furnitureList = self.HomeRoomData:GetFurnitureDic()
    for _, v in pairs(furnitureList) do
        roomData:AddFurniture(v.Id, v.ConfigId, v.GridX, v.GridY, v.RotateAngle)
    end
    XDataCenter.FurnitureManager.SetCollectNoneFurnitrue(dormitoryId, roomData:GetFurnitureDic())
end

function XUiDormTemplateScene:SetBtnStatus()
    if self.OldRoomDataType == XDormConfig.DormDataType.Target then
        self.BtnShare.gameObject:SetActiveEx(true)
        self.BtnDown.gameObject:SetActiveEx(false)

        self.BtnSet.gameObject:SetActiveEx(false)
        self.BtnSave.gameObject:SetActiveEx(true)
    elseif self.OldRoomDataType == XDormConfig.DormDataType.Template then
        self.BtnShare.gameObject:SetActiveEx(false)
        self.BtnDown.gameObject:SetActiveEx(false)
        self.BtnSet.gameObject:SetActiveEx(false)
        self.BtnSave.gameObject:SetActiveEx(false)
    elseif self.OldRoomDataType == XDormConfig.DormDataType.Collect or
    self.OldRoomDataType == XDormConfig.DormDataType.CollectNone then
        self.BtnShare.gameObject:SetActiveEx(self.OldRoomDataType == XDormConfig.DormDataType.Collect)
        self.BtnDown.gameObject:SetActiveEx(true)

        self.BtnSet.gameObject:SetActiveEx(true)
        self.BtnSave.gameObject:SetActiveEx(true)
    elseif self.OldRoomDataType == XDormConfig.DormDataType.Provisional then
        self.BtnShare.gameObject:SetActiveEx(true)
        self.BtnDown.gameObject:SetActiveEx(true)

        self.BtnSet.gameObject:SetActiveEx(true)
        self.BtnSave.gameObject:SetActiveEx(true)
    end
    --海外特供屏蔽宿舍分享按钮
    self.BtnShare.gameObject:SetActiveEx(false)
    self.BtnDown.gameObject:SetActiveEx(false)
end