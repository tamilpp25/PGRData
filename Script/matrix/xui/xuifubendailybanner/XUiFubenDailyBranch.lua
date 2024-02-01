local XUiFubenDailyBranch = XLuaUiManager.Register(XLuaUi, "UiFubenDaily")
local stringGsub = string.gsub
local STAGE_COUNT_MAX = 5

function XUiFubenDailyBranch:OnAwake()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self:AutoAddListener()

    self.PaneStageScrollRect = self.PaneStageList.transform:GetComponent(typeof(CS.UnityEngine.UI.ScrollRect))
    self.HorizontalLayoutGroup = self.PanelStageContent.gameObject:GetComponent(typeof(CS.UnityEngine.UI.HorizontalLayoutGroup))
end

function XUiFubenDailyBranch:OnStart(Rule)
    self.Rule = Rule
    self.DungeonId = self.Rule.DungeonOfWeek[XDataCenter.FubenDailyManager.GetNowDayOfWeekByRefreshTime()]

    self.Stage = {}
    self.StageObjs = {}
end

function XUiFubenDailyBranch:OnEnable()
    self:InitShop()
    self:StageRefresh()
    XEventManager.AddEventListener(XEventId.EVENT_AUTO_FIGHT_START, self.OnAutoFightStart, self)
end

function XUiFubenDailyBranch:OnResume()
    self.AssetPanel:Open()
end

function XUiFubenDailyBranch:InitShop()
    self.ShopId = XDailyDungeonConfigs.GetFubenDailyShopId(self.Rule.Id)
    self.BtnShop.gameObject:SetActiveEx(self.ShopId > 0)
    self.BtnShop:SetName(XShopManager.GetShopTypeDataById(XShopManager.ShopType.FubenDaily).Desc)
    self.BtnShop:ShowReddot(false)
    if XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.FubenDailyShop) then
        if self.ShopId > 0 then
            XShopManager.GetShopInfo(self.ShopId, function()
                local shopItemList = XShopManager.GetShopGoodsList(self.ShopId)
                self:AddRedPointEvent(self.BtnShop, self.OnCheckShopNew, self, { XRedPointConditions.Types.CONDITION_FUBEN_DAILY_SHOP }, shopItemList)
            end)
        end
    end
end

function XUiFubenDailyBranch:StageRefresh()
    if not self.StageObjs then
        return
    end

    local dungeoData = XDailyDungeonConfigs.GetDailyDungeonData(self.DungeonId)
    local exValue = 0
    self.TxtTitle.text = dungeoData.Name
    self.BgCommonBai:SetRawImage(dungeoData.BgImg)

    for i = 1, STAGE_COUNT_MAX do
        if not self.StageObjs[i] then
            local temp
            temp = CS.UnityEngine.Object.Instantiate(self.FubenDailyStageObj)
            temp.transform:SetParent(self.PanelStageContent.transform, false)
            table.insert(self.StageObjs, temp)
        end
        self.StageObjs[i].gameObject:SetActive(false)
    end

    self.StageCount = 0
    for k, v in pairs(dungeoData.StageId) do
        if v ~= 0 then
            if not self.Stage[k] then
                self.Stage[k] = XUiFubenDailyStage.New(self, self.StageObjs[k], v, exValue, dungeoData, k)
            else
                self.Stage[k]:ReSetStageCfg()
            end
            self.Stage[k]:SetCallBack(function(num, IsOpen)
                self:StageIconMove(num, IsOpen)
            end)
            self.StageObjs[k].gameObject:SetActive(true)

            self.StageCount = self.StageCount + 1
        else
            self.StageObjs[k].gameObject:SetActive(false)
        end
        exValue = v
    end

    if self.StageCount >= 5 then
        self.HorizontalLayoutGroup.padding.left = -960
        self.HorizontalLayoutGroup.spacing = 180
    else
        self.HorizontalLayoutGroup.padding.left = -720
        self.HorizontalLayoutGroup.spacing = 230
    end
end

function XUiFubenDailyBranch:StageIconMove(num, IsOpen)
    if IsOpen then
        local grid = self.PanelStageContent.transform:GetChild(num - 1)
        if grid then
            self:PlayScrollViewMove(grid)
        end
    else
        local zeroPos = { 0, 0, 0 }
        XUiHelper.DoMove(self.PaneStageList, zeroPos, 0.3, XUiHelper.EaseType.Sin)
    end
end

function XUiFubenDailyBranch:PlayScrollViewMove(grid)
    self.PaneStageScrollRect.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted

    local gridTf = grid.gameObject:GetComponent("RectTransform")
    self.LastContentPosX = self.PanelStageContent.localPosition.x

    local tarPosX = XDataCenter.FubenMainLineManager.UiGridChapterMoveTargetX - gridTf.localPosition.x
    local tarPos = self.PanelStageContent.localPosition
    tarPos.x = tarPosX

    XLuaUiManager.SetMask(true)
    XUiHelper.DoMove(self.PanelStageContent, tarPos, 0.5, XUiHelper.EaseType.Sin, function()
        XLuaUiManager.SetMask(false)
    end)
end

function XUiFubenDailyBranch:PlayScrollViewMoveBack(noAnim)
    local tarPos = self.PanelStageContent.localPosition
    tarPos.x = self.LastContentPosX

    if noAnim then
        self.PanelStageContent.localPosition = tarPos
        self.PaneStageScrollRect.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
    else
        XLuaUiManager.SetMask(true)
        XUiHelper.DoMove(self.PanelStageContent, tarPos, 0.3, XUiHelper.EaseType.Sin, function()
            self.PaneStageScrollRect.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
            XLuaUiManager.SetMask(false)
        end)
    end
end

function XUiFubenDailyBranch:AutoAddListener()
    self.BtnBack.CallBack = function(eventData)
        self:OnBtnBackClick(eventData)
    end
    self.BtnMainUi.CallBack = function(eventData)
        self:OnBtnMainUiClick(eventData)
    end
    self.BtnActDesc.CallBack = function(eventData)
        self:OnBtnActDescClick(eventData)
    end
    self.BtnShop.CallBack = function(eventData)
        self:OnBtnShopClick(eventData)
    end
end

function XUiFubenDailyBranch:OnBtnBackClick()
    self:Close()
end

function XUiFubenDailyBranch:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiFubenDailyBranch:OnBtnActDescClick()
    local dungeoData = XDailyDungeonConfigs.GetDailyDungeonData(self.DungeonId)
    local description = stringGsub(dungeoData.Description, "\\n", "\n")
    XUiManager.UiFubenDialogTip("", description)
end

function XUiFubenDailyBranch:OnBtnShopClick()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.FubenDailyShop) then
        return
    end

    if not self.ShopId then
        return
    end

    XShopManager.GetBaseInfo(function()
        XShopManager.GetShopInfo(self.ShopId, function()
            XLuaUiManager.Open("UiFubenDailyShop", self.ShopId)
        end)
    end)
end

function XUiFubenDailyBranch:OnGetEvents()
    return { XEventId.EVENT_FUBEN_CLOSE_FUBENSTAGEDETAIL, XEventId.EVENT_FUBEN_ENTERFIGHT, XEventId.EVENT_FUBEN_RESOURCE_AUTOSELECT }
end

--事件监听
function XUiFubenDailyBranch:OnNotify(evt, ...)
    local args = { ... }
    if evt == XEventId.EVENT_FUBEN_ENTERFIGHT then
        self:EnterFight(args[1])
    elseif evt == XEventId.EVENT_FUBEN_RESOURCE_AUTOSELECT then
        if not self.DungeonId then return end
        local stageId = args[1]
        local dungeoData = XDailyDungeonConfigs.GetDailyDungeonData(self.DungeonId)
        if not dungeoData then return end

        for k, v in pairs(dungeoData.StageId) do
            if stageId and v == stageId and self.Stage[k] then
                self.Stage[k]:OnBtnEnter()
                break
            end
        end
    elseif evt == XEventId.EVENT_FUBEN_CLOSE_FUBENSTAGEDETAIL then
        self:PlayScrollViewMoveBack()
    end
end

function XUiFubenDailyBranch:EnterFight(stage)
    if XDataCenter.FubenManager.OpenBattleRoom(stage) then
        XLuaUiManager.Remove("UiFubenStageDetail")
    end
end

function XUiFubenDailyBranch:ShowPanelAsset(IsShow)
    if XTool.UObjIsNil(self.GameObject) or not self.GameObject.activeInHierarchy then return end

    if IsShow then
        self.AssetPanel:Open()
    else
        self.AssetPanel:Close()
    end
end

function XUiFubenDailyBranch:OnCheckShopNew(count)
    self.BtnShop:ShowReddot(count >= 0)
end

function XUiFubenDailyBranch:OnAutoFightStart()
    self:PlayScrollViewMoveBack(true)
    XLuaUiManager.Remove("UiFubenStageDetail")
end

function XUiFubenDailyBranch:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_AUTO_FIGHT_START, self.OnAutoFightStart, self)
end

function XUiFubenDailyBranch:OnDestroy()
    self.PaneStageScrollRect = nil
    self.HorizontalLayoutGroup = nil
end