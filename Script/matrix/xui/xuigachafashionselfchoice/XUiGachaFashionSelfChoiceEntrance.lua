local XUiGachaFashionSelfChoiceEntrance = XLuaUiManager.Register(XLuaUi, "UiGachaFashionSelfChoiceEntrance")

function XUiGachaFashionSelfChoiceEntrance:OnAwake()
    self.ActivityId = XDataCenter.GachaManager.GetCurGachaFashionSelfChoiceActivityId()
    self.ActivityConfig = XDataCenter.GachaManager.GetCurGachaFashionSelfChoiceActivityConfig()
    self.CurSelectGridIndex = 1
    self.CurSelectGrid = nil
    self.GridRewardDic = {}
    self:InitButton()
    self:InitDynamicTable()
    self:InitTimes()
end

function XUiGachaFashionSelfChoiceEntrance:InitButton()
    self.BtnHelp.CallBack = function() XLuaUiManager.Open("UiGachaFashionSelfChoiceDescribe") end
    self.BtnBack.CallBack = function() self:Close() end
    self.BtnMainUi.CallBack = function() XLuaUiManager.RunMain() end
    self.BtnChoose.CallBack = function() self:OnBtnChooseClick() end
    self.BtnAudio.CallBack = function() XLuaUiManager.Open("UiSet") end
    self.AssetPanel = XUiHelper.XUiPanelAsset(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.HongKa)
end

function XUiGachaFashionSelfChoiceEntrance:InitDynamicTable()
    local grid = require("XUi/XUiGachaFashionSelfChoice/Grid/XUiDTGridGachaSelect")
    self.DynamicTable = XUiHelper.DynamicTableNormal(self, self.GachaList, grid, function (index, gachaId, gridProxy)
        self:OnGridGachaSelect(index, gachaId, gridProxy)
    end)
end

function XUiGachaFashionSelfChoiceEntrance:InitTimes()
    local endTime = XFunctionManager.GetEndTimeByTimeId(self.ActivityConfig.TimeId) or 0
    self.EndTime = endTime
    self:RefreshTitleByTimeId() -- 计时器启动比较慢 先提前刷新一次
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            XLuaUiManager.RunMain()
            XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
        else
            self:RefreshTitleByTimeId()
        end
    end)
end

function XUiGachaFashionSelfChoiceEntrance:RefreshTitleByTimeId()
    local timeSecond =  self.EndTime - XTime.GetServerNowTimestamp()
    self.TxtLeftTime.text = XUiHelper.GetTime(timeSecond, XUiHelper.TimeFormatType.CHATEMOJITIMER)
end

function XUiGachaFashionSelfChoiceEntrance:OnEnable()
    local curSelectGachaId = XDataCenter.GachaManager.GetCurSelfChoiceSelectGachId()
    if XTool.IsNumberValid(curSelectGachaId) then
        self:Close()
        return
    end

    self:RefreshDynamicTable()
    XSaveTool.SaveData("OpenUiGachaFashionSelfChoiceEntrance", {NextCanShowTimeStamp = XTime.GetSeverTomorrowFreshTime()})
end

function XUiGachaFashionSelfChoiceEntrance:RefreshDynamicTable()
    local dataList = self.ActivityConfig.GachaId
    self.DynamicTable:SetDataSource(dataList)
    self.DynamicTable:ReloadDataSync()
end

---@param event any
---@param index any
---@param grid XUiDTGridGachaSelect
function XUiGachaFashionSelfChoiceEntrance:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local gachaId = self.DynamicTable.DataSource[index]
        grid:Refresh(gachaId, index)
        if self.CurSelectGridIndex == index then
            -- self:OnGridGachaSelect(index, gachaId, grid)
            grid:OnSelect()
            grid:SetSelect()
        else
            grid:SetUnSelect()
        end
    -- elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
    -- 点击由Btn的回调去处理
    end
end

function XUiGachaFashionSelfChoiceEntrance:OnGridGachaSelect(index, gachaId, grid)
    if self.CurSelectGachaId == gachaId then
        self.CurSelectGrid:SetSelect()
        return
    end

    -- 格子被选中后的切换逻辑
    self:PlayAnimation("QieHuan")
    grid:SetSelect()
    if self.CurSelectGrid then
        self.CurSelectGrid:SetUnSelect()
    end
    self.CurSelectGrid = grid
    self.CurSelectGridIndex = index
    self.CurSelectGachaId = gachaId

    -- 同步其他ui显示的信息的逻辑
    ---@type XTableGachaFashionSelfChoiceResources
    local gachaConfig = XGachaConfigs.GetAllConfigs(XGachaConfigs.TableKey.GachaFashionSelfChoiceResources)[gachaId]
    self.VideoPlayer:SetInfoByVideoId(gachaConfig.VideoConfigId)
    self.VideoPlayer:RePlay()

    local fashionId = gachaConfig.SpecialRewardTemplateIds[1] -- 第1个默认是涂装id(写死)
    local fashionConfig = XFashionConfigs.GetFashionTemplate(fashionId)
    local backgroundId = gachaConfig.SpecialRewardTemplateIds[2] -- 第2个默认是场景id(写死)
    local backgroundName = XPhotographConfigs.GetBackgroundNameById(backgroundId)
    local characterId = fashionConfig.CharacterId
    self.TxtCharacterName.text = XMVCA.XCharacter:GetCharacterFullNameStr(characterId)
    self.TxtFashionName.text = fashionConfig.Name
    self.TxtSceneName.text = backgroundName

    -- 奖励
    local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
    for k, templateId in ipairs(gachaConfig.SpecialRewardTemplateIds) do
        local grid = self.GridRewardDic[k]
        if not grid then
            local ui = (k == 1) and self.Grid256New or XUiHelper.Instantiate(self.Grid256New, self.Grid256New.parent)
            grid = XUiGridCommon.New(self, ui)
            self.GridRewardDic[k] = grid
        end

        grid:Refresh({ TemplateId = templateId })
    end
end

function XUiGachaFashionSelfChoiceEntrance:OnBtnChooseClick()
    ---@type XTableGachaFashionSelfChoiceResources
    local gachaConfig = XGachaConfigs.GetAllConfigs(XGachaConfigs.TableKey.GachaFashionSelfChoiceResources)[self.CurSelectGachaId]
    -- 检测是否弹出弹窗提示
    XLuaUiManager.Open("UiGachaFashionSelfChoiceDialog", self.CurSelectGachaId, self.CurSelectGrid.IsAllRewardGet, function ()
        XDataCenter.GachaManager.ChoiceGachaRequest(self.CurSelectGachaId, function ()
            -- self:Close()
            XFunctionManager.SkipInterface(gachaConfig.SkipId)
        end)
    end)
end