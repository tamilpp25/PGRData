-- 兵法蓝图成员列表主页面
local XUiRpgTowerRoleList = XLuaUiManager.Register(XLuaUi, "UiRpgTowerRoleList")
local XUiRpgTowerRoleListCharaInfo = require("XUi/XUiRpgTower/CharacterPage/MainPage/XUiRpgTowerRoleListCharaInfo")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

local XUiRpgTowerRoleListMainPage = require("XUi/XUiRpgTower/CharacterPage/MainPage/XUiRpgTowerRoleListMainPage")
local XUiRpgTowerRoleListAdaptPage = require("XUi/XUiRpgTower/CharacterPage/AdaptPage/XUiRpgTowerRoleListAdaptPage")
local XUiRpgTowerRoleListChangeMemberPage = require("XUi/XUiRpgTower/CharacterPage/ChangeMemberPage/XUiRpgTowerRoleListChangeMemberPage")
local XUiRpgTowerRoleListTypeSelectPage = require("XUi/XUiRpgTower/CharacterPage/TalentSelectPage/XUiRpgTowerRoleListTypeSelectPage")
-- 3D场景相机数量
local CAMERA_NUM = 5
-- 子页面枚举
local PARENT_PAGE
-- 子页面控件脚本字典
local ChildUiPage

function XUiRpgTowerRoleList:OnAwake()
    XTool.InitUiObject(self)
    XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self:InitChildUiPageData()
    self:InitButtons()
    self:InitModel()
    self.ChildPage = {}
end

function XUiRpgTowerRoleList:OnEnable()
    self:OnRefresh(self.RollIndex)
    self:UpdateModel(self.RCharacter)
    self:RefreshBtnRedPoint()
    self.RollIndex = nil
end

function XUiRpgTowerRoleList:OnStart(index)
    self.RollIndex = index
    if index and index > 0 then
        self.AutoOpen = true -- 选中列表后自动打开到天赋界面
    end
end

function XUiRpgTowerRoleList:OnDestroy()
    self:ChildPageOnCollect()
end

function XUiRpgTowerRoleList:OnGetEvents()
    return { XEventId.EVENT_RPGTOWER_RESET, XEventId.EVENT_RPGTOWER_MEMBERCHANGE }
end

function XUiRpgTowerRoleList:OnNotify(evt, ...)
    local args = { ... }
    if evt == XEventId.EVENT_RPGTOWER_RESET then
        self:OnActivityReset()
    elseif evt == XEventId.EVENT_RPGTOWER_MEMBERCHANGE then
        self:OnMemberChange()
    end
end

--================
--活动周期结束时弹回主界面
--================
function XUiRpgTowerRoleList:OnActivityReset()
    XLuaUiManager.RunMain()
    XUiManager.TipMsg(CS.XTextManager.GetText("RpgTowerFinished"))
end

--================
--初始化枚举与字典
--================
function XUiRpgTowerRoleList:InitChildUiPageData()
    PARENT_PAGE = {
        MAIN = XDataCenter.RpgTowerManager.PARENT_PAGE.MAIN, -- 主页面
        ADAPT = XDataCenter.RpgTowerManager.PARENT_PAGE.ADAPT, -- 改造页面
        CHANGEMEMBER = XDataCenter.RpgTowerManager.PARENT_PAGE.CHANGEMEMBER, -- 切换队员
        TYPESELECT = XDataCenter.RpgTowerManager.PARENT_PAGE.TYPESELECT, --选择天赋类型入口
    }
    ChildUiPage = {
        [PARENT_PAGE.MAIN] = XUiRpgTowerRoleListMainPage,
        [PARENT_PAGE.ADAPT] = XUiRpgTowerRoleListAdaptPage,
        [PARENT_PAGE.CHANGEMEMBER] = XUiRpgTowerRoleListChangeMemberPage,
        [PARENT_PAGE.TYPESELECT] = XUiRpgTowerRoleListTypeSelectPage
    }
end
--================
--初始化按钮事件
--================
function XUiRpgTowerRoleList:InitButtons()
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end

    self.BtnFashion.CallBack = function() self:OnBtnFashionClick() end
    self.BtnOwnedDetail.CallBack = function() self:OnBtnOwnedDetailClick() end
    self.BtnTeaching.CallBack = function() self:OnBtnTeachingClick() end
    self:BindHelpBtn(self.BtnHelp, "RpgTowerHelp")
end
--================
--返回按钮事件
--================
function XUiRpgTowerRoleList:OnBtnBackClick()
    if self.CurrentPageIndex == PARENT_PAGE.ADAPT then
        self:OpenChildPage(PARENT_PAGE.TYPESELECT)
        return
    elseif self.CurrentPageIndex == PARENT_PAGE.CHANGEMEMBER then
        self:OpenChildPage(PARENT_PAGE.ADAPT)
        return
    elseif self.CurrentPageIndex == PARENT_PAGE.TYPESELECT then
        self:OpenChildPage(PARENT_PAGE.MAIN)
        return
    end
    self:Close()
end
--================
--主界面按钮事件
--================
function XUiRpgTowerRoleList:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end
--================
--页面刷新时
--================
function XUiRpgTowerRoleList:OnRefresh(index)
    -- 默认第一次打开MAIN页面，若不是第一次打开，则打开最后停留的子页面
    self:OpenChildPage(self.CurrentPageIndex or PARENT_PAGE.MAIN, index)
end

-- 刷新按钮红点
function XUiRpgTowerRoleList:RefreshBtnRedPoint()
    if not self.RCharacter then
        return
    end
    -- 红点：有可更换时装就显示1次性红点
    local isShowFashion = not XSaveTool.GetData(string.format("%s%s%s", "RpgTowerRoleListFashionRedPoint", XPlayer.Id, self.RCharacter:GetId())) and XDataCenter.FashionManager.GetCurrCharHaveCanChangeFashion(self.RCharacter:GetId())
    self.BtnFashion:ShowReddot(isShowFashion)
    -- 红点：未拥有角色显示1次性红点
    local isShowTech = not XSaveTool.GetData(string.format("%s%s%s", "RpgTowerRoleListTeachRedPoint", XPlayer.Id, self.RCharacter:GetId())) and not XMVCA.XCharacter:IsOwnCharacter(self.RCharacter:GetId()) 
    self.BtnTeaching:ShowReddot(isShowTech)
end
--================
--当选择角色时
--================
function XUiRpgTowerRoleList:OnCharaSelect(rChara, updateModelCb)
    self.RCharacter = rChara
    self:UpdateModel(rChara, updateModelCb)
    self:RefreshBtnRedPoint()
    self:ChildPageOnCharaSelect(rChara)

    if self.AutoOpen then
        self:OpenChildPage(PARENT_PAGE.TYPESELECT)
        self.AutoOpen = false
    end
end
--================
--子页面切换角色选择
--================
function XUiRpgTowerRoleList:ChildPageOnCharaSelect(rChara)
    if self.ChildPage[self.CurrentPageIndex] then self.ChildPage[self.CurrentPageIndex]:RefreshPage(rChara) end
end
--================
--当角色数据刷新时
--================
function XUiRpgTowerRoleList:OnMemberChange()
    -- 刷新当前页面
    self.ChildPage[self.CurrentPageIndex]:RefreshPage(self.RCharacter)
    self:UpdateModel(self.RCharacter)
end
--================
--初始化角色模型和场景相机
--================
function XUiRpgTowerRoleList:InitModel()
    local root = self.UiModelGo.transform
    self.PanelRoleModel = root:FindTransform("PanelRoleModel")
    self.ImgEffectHuanren = root:FindTransform("ImgEffectHuanren")
    self.ImgEffectHuanren1 = root:FindTransform("ImgEffectHuanren1")
    self.ImgEffectLogoGouzao = root:FindTransform("ImgEffectLogoGouzao")
    self.ImgEffectLogoGanran = root:FindTransform("ImgEffectLogoGanran")
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
    self.RoleModelPanel = XUiPanelRoleModel.New(self.PanelRoleModel, self.Name, nil, true, nil, true)
end
--================
--刷新场景相机
--================
function XUiRpgTowerRoleList:UpdateCamera(cameraIndex)
    self.CurCameraIndex = cameraIndex
    for i = 1, CAMERA_NUM do
        if self.CurCameraIndex ~= i then
            self.CameraFar[i].gameObject:SetActiveEx(false)
            self.CameraNear[i].gameObject:SetActiveEx(false)
        end
    end

    if self.CameraFar[self.CurCameraIndex] then
        self.CameraFar[self.CurCameraIndex].gameObject:SetActiveEx(true)
    end

    if self.CameraNear[self.CurCameraIndex] then
        self.CameraNear[self.CurCameraIndex].gameObject:SetActiveEx(true)
    end
end
--================
--刷新模型
--================
function XUiRpgTowerRoleList:UpdateModel(rChara, updateModelCb)
    if not rChara then
        return
    end

    self.ImgEffectHuanren.gameObject:SetActiveEx(false)
    local cb = function(model)
        self.PanelDrag.Target = model.transform
        self.ImgEffectHuanren.gameObject:SetActiveEx(true)
        if updateModelCb then updateModelCb(model) end
    end
    local robotCfg = XRobotManager.GetRobotTemplate(rChara:GetRobotId())
    self.RoleModelPanel:UpdateRobotModelNew(rChara:GetRobotId(), rChara:GetCharacterId(), nil, robotCfg and robotCfg.FashionId, robotCfg and robotCfg.WeaponId, cb)
end
--================
--打开子页面，打开新页面时会关闭旧的子页面
--================
function XUiRpgTowerRoleList:OpenChildPage(pageIndex, ...)
    if self.CurrentPageIndex == pageIndex then return end
    if self.CurrentPageIndex then
        self.ChildPage[self.CurrentPageIndex]:HidePage()
    end
    self.PrePageIndex = self.CurrentPageIndex
    if self.ChildPage[pageIndex] then
        self.CurrentPageIndex = pageIndex
        self.ChildPage[self.CurrentPageIndex]:ShowPage(...)
        self.ChildPage[self.CurrentPageIndex]:RefreshPage(self.RCharacter)
        return
    end
    self.CurrentPageIndex = pageIndex
    self.ChildPage[pageIndex] = ChildUiPage[pageIndex].New(self)
    self.ChildPage[pageIndex]:ShowPage(...)
    if self.RCharacter then self.ChildPage[pageIndex]:RefreshPage(self.RCharacter) end
end

function XUiRpgTowerRoleList:OpenPreChildPage(...)
    self.ChildPage[self.CurrentPageIndex]:HidePage()
    local tempIndex = self.PrePageIndex
    self.PrePageIndex = self.CurrentPageIndex
    self.CurrentPageIndex = tempIndex
    self.ChildPage[self.CurrentPageIndex]:ShowPage(...)
    self.ChildPage[self.CurrentPageIndex]:RefreshPage(self.RCharacter)
    
end
--================
--关闭子页面
--================
function XUiRpgTowerRoleList:CloseChildPage(pageIndex)
    if self.ChildPage[pageIndex] then self.ChildPage[pageIndex]:HidePage() end
end
--================
--回收子页面
--================
function XUiRpgTowerRoleList:ChildPageOnCollect()
    for _, page in pairs(self.ChildPage) do
        if page.OnCollect then page:OnCollect() end
    end
end
--================
--读取面板控件
--================
function XUiRpgTowerRoleList:LoadChildPrefab(pageIndex, assetPath)
    return self["Panel" .. pageIndex]:LoadPrefab(assetPath)
end
--================
--设置滑动
--================
function XUiRpgTowerRoleList:SetModelDragFieldActive(isActive)
    self.PanelDrag.gameObject:SetActiveEx(isActive)
end

function XUiRpgTowerRoleList:OnBtnFashionClick()
    XLuaUiManager.Open("UiFashion", self.RCharacter:GetId())
    XSaveTool.SaveData(string.format("%s%s%s", "RpgTowerRoleListFashionRedPoint", XPlayer.Id, self.RCharacter:GetId()), true)
end

function XUiRpgTowerRoleList:OnBtnOwnedDetailClick()
    XLuaUiManager.Open("UiCharacterDetail", self.RCharacter:GetId())
end

function XUiRpgTowerRoleList:OnBtnTeachingClick()
    XDataCenter.PracticeManager.OpenUiFubenPractice(self.RCharacter:GetId())
    XSaveTool.SaveData(string.format("%s%s%s", "RpgTowerRoleListTeachRedPoint", XPlayer.Id, self.RCharacter:GetId()), true)
end