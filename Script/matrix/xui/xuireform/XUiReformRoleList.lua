--######################## XUiReformRoleGrid ########################
local XUiReformRoleGrid = XClass(nil, "XUiReformRoleGrid")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

function XUiReformRoleGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.Source = nil
    self.ClickProxy = nil
    self.ClickCallBack = nil
    self.BtnClick.CallBack = function() self:OnBtnClicked() end
end

-- source : MemberSource | MemberTarget
function XUiReformRoleGrid:SetData(source, isSelect)
    self.Source = source
    local characterViewModel = source:GetRobot():GetCharacterViewModel()
    -- 头像
    self.RImgHeadIcon:SetRawImage(source:GetSmallHeadIcon())
    -- 战力
    self.TxtFight.text = characterViewModel:GetAbility()
    -- 等级
    self.TxtLevel.text = characterViewModel:GetLevel()
    -- 品质
    self.RImgQuality:SetRawImage(characterViewModel:GetQualityIcon())
    -- 元素列表
    local elementList = characterViewModel:GetObtainElements()
    local rImg = nil
    for i = 1, 3 do
        rImg = self["RImgCharElement" .. i]
        if elementList[i] then
            rImg.gameObject:SetActiveEx(true)
            rImg:SetRawImage(XMVCA.XCharacter:GetCharElement(elementList[i]).Icon)
        else
            rImg.gameObject:SetActiveEx(false)
        end
    end
    self:SetSelectStatus(isSelect)
end

function XUiReformRoleGrid:SetSelectStatus(value)
    self.PanelSelected.gameObject:SetActiveEx(value)
end

function XUiReformRoleGrid:SetSelectStatusBySource(source)
    self.PanelSelected.gameObject:SetActiveEx(self.Source == source)
end

function XUiReformRoleGrid:SetClickCallback(clickProxy, callback)
    self.ClickProxy = clickProxy
    self.ClickCallBack = callback
end

function XUiReformRoleGrid:OnBtnClicked()
    if self.ClickCallBack then
        self.ClickCallBack(self.ClickProxy, self.Source)
    end
end

--######################## XUiReformRoleList ########################
local XUiReformCharacterInfo = require("XUi/XUiReform/XUiReformCharacterInfo")
local XUiReformRoleList = XLuaUiManager.Register(XLuaUi, "UiReformRoleList")

function XUiReformRoleList:OnAwake()
    self.Sources = nil
    self.CurrentSource = nil
    self:RegisterUiEvents()
    self.UiRoleGrids = {}
    self.GridCharacter.gameObject:SetActiveEx(false)
    -- 模型相关
    local root = self.UiModelGo.transform
    local panelRoleModel = root:FindTransform("PanelRoleModel")
    -- XEnumConst.CHARACTER.XUiCharacter_Camera.MAIN
    self.CameraFar = {
        root:FindTransform("UiCamFarLv"),
        root:FindTransform("UiCamFarGrade"),
        root:FindTransform("UiCamFarQuality"),
        root:FindTransform("UiCamFarSkill"),
        root:FindTransform("UiCamFarrExchange"),
    }
    self.CameraNear = {
        root:FindTransform("UiCamNearLv"),
        root:FindTransform("UiCamNearGrade"),
        root:FindTransform("UiCamNearQuality"),
        root:FindTransform("UiCamNearSkill"),
        root:FindTransform("UiCamNearrExchange"),
    }
    self.ImgEffectHuanren = root:FindTransform("ImgEffectHuanren")
    self.UiPanelRoleModel = XUiPanelRoleModel.New(panelRoleModel, self.Name, nil, true, nil, true)
    -- 资源
    XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem
    , XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    -- 基础信息面板    
    self.UiReformCharacterInfo = self:FindChildUiObj("UiReformCharacterInfo")
    self.UiReformCharacterDetailInfo = self:FindChildUiObj("UiReformCharacterDetailInfo")
    -- 自动关闭
    local endTime = XDataCenter.ReformActivityManager.GetActivityEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            XDataCenter.ReformActivityManager.HandleActivityEndTime()
        end
    end)
end

function XUiReformRoleList:OnStart(sources, index)
    self.Sources = sources
    self.CurrentSource = sources[index]
    -- 刷新模型
    self:RefreshModel()
    -- 刷新列表
    self:RefreshRoleList()
    self:OpenUiReformCharacterInfo()
end

--######################## 私有方法 ########################
function XUiReformRoleList:RegisterUiEvents()
    self.BtnBack.CallBack = function() self:OnBtnBackClicked() end
    self.BtnMainUi.CallBack = function() XLuaUiManager.RunMain() end
    self:BindHelpBtn(self.BtnHelp, XDataCenter.ReformActivityManager.GetHelpName())
end

function XUiReformRoleList:OnBtnBackClicked()
    if XLuaUiManager.IsUiShow("UiReformCharacterDetailInfo") then
        self:CloseChildUi("UiReformCharacterDetailInfo")
        self:OpenUiReformCharacterInfo()
        return
    end
    self:Close()
end

function XUiReformRoleList:RefreshRoleList()
    local go = nil
    local grid = nil
    for index, source in ipairs(self.Sources) do
        go = CS.UnityEngine.Object.Instantiate(self.GridCharacter, self.PanelRoleContent)
        go.gameObject:SetActiveEx(true)
        grid = XUiReformRoleGrid.New(go)
        grid:SetData(source, source == self.CurrentSource)
        grid:SetClickCallback(self, self.OnRoleGridClicked)
        self.UiRoleGrids[index] = grid
    end
end

function XUiReformRoleList:OnRoleGridClicked(source)
    self.CurrentSource = source
    self:RefreshModel()
    self:OpenUiReformCharacterInfo()
    -- 刷新选中状态
    for _, grid in ipairs(self.UiRoleGrids) do
        grid:SetSelectStatusBySource(source)
    end
end

function XUiReformRoleList:RefreshModel()
    local robotId = self.CurrentSource:GetRobotId()
    local robotCfg = XRobotManager.GetRobotTemplate(robotId)
    local characterId = XRobotManager.GetCharacterId(robotId)
    self.ImgEffectHuanren.gameObject:SetActiveEx(false)
    self.UiPanelRoleModel:UpdateRobotModel(robotId, characterId, nil
    , robotCfg.FashionId, robotCfg.WeaponId, function(model)
        self.PanelDrag.Target = model.transform
        self.ImgEffectHuanren.gameObject:SetActiveEx(true)
    end)
end

function XUiReformRoleList:RefreshBaseInfo()
    self.UiReformCharacterInfo:Open()
    self.UiReformCharacterInfo:SetData(self.CurrentSource)
end

function XUiReformRoleList:OpenUiReformCharacterInfo()
    self:OpenOneChildUi("UiReformCharacterInfo", self)
    self.SViewCharacterList.gameObject:SetActiveEx(true)
    self.UiReformCharacterInfo:Open()
    self.UiReformCharacterInfo:SetData(self.CurrentSource)
    self:SetCameraType(0)
end

function XUiReformRoleList:OpenUiReformCharacterDetailInfo()
    -- 隐藏左边的列表
    self.SViewCharacterList.gameObject:SetActiveEx(false)
    -- 隐藏基本信息面板
    self.UiReformCharacterInfo:Close()
    -- 打开属性信息面板
    self:OpenOneChildUi("UiReformCharacterDetailInfo", self)
    self.UiReformCharacterDetailInfo:SetData(self.CurrentSource)
    self:SetCameraType(1)
end

function XUiReformRoleList:SetCameraType(index)
    for k, _ in pairs(self.CameraFar) do
        self.CameraFar[k].gameObject:SetActiveEx(k == index)
    end
    for k, _ in pairs(self.CameraNear) do
        self.CameraNear[k].gameObject:SetActiveEx(k == index)
    end
end

return XUiReformRoleList