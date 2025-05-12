local XUiLottoFashionSelfChoiceEntrance = XLuaUiManager.Register(XLuaUi, "UiLottoFashionSelfChoiceEntrance")

function XUiLottoFashionSelfChoiceEntrance:OnAwake()
    self.LottoPrimaryId = XDataCenter.LottoManager.GetCurSelfChoiceLottoPrimaryId()
    self.LottoPrimaryCfg = XLottoConfigs.GetLottoPrimaryCfgById(self.LottoPrimaryId)
    if not XTool.IsNumberValid(self.LottoPrimaryId) or XTool.IsTableEmpty(self.LottoPrimaryCfg) then
        return
    end
    self.CurSelectGridIndex = 1
    self.CurSelectGrid = nil
    self.GridRewardDic = {}
    self:InitButton()
    self:InitDynamicTable()
    self:InitTimes()
end

function XUiLottoFashionSelfChoiceEntrance:InitButton()
    self.BtnHelp.CallBack = function() XLuaUiManager.Open("UiLottoFashionSelfChoiceDescribe", self.LottoPrimaryId) end
    self.BtnBack.CallBack = function() self:Close() end
    self.BtnMainUi.CallBack = function() XLuaUiManager.RunMain() end
    self.BtnChoose.CallBack = function() self:OnBtnChooseClick() end
    self.BtnAudio.CallBack = function() XLuaUiManager.Open("UiSet") end
    self.AssetPanel = XUiHelper.XUiPanelAsset(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.HongKa)
end

function XUiLottoFashionSelfChoiceEntrance:InitDynamicTable()
    local grid = require("XUi/XUiLottoFashionSelfChoice/Grid/XUiDTGridLottoSelect")
    self.DynamicTable = XUiHelper.DynamicTableNormal(self, self.LottoList, grid, function (index, lottoId, gridProxy)
        self:OnGridSelect(index, lottoId, gridProxy)
    end)
end

function XUiLottoFashionSelfChoiceEntrance:InitTimes()
    local endTime = XFunctionManager.GetEndTimeByTimeId(self.LottoPrimaryCfg.TimeId) or 0
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

function XUiLottoFashionSelfChoiceEntrance:RefreshTitleByTimeId()
    local timeSecond =  self.EndTime - XTime.GetServerNowTimestamp()
    self.TxtLeftTime.text = XUiHelper.GetTime(timeSecond, XUiHelper.TimeFormatType.CHATEMOJITIMER)
end

function XUiLottoFashionSelfChoiceEntrance:OnEnable()
    local curSelectLottoId = XDataCenter.LottoManager.GetCurSelectedLottoIdByPrimartLottoId(self.LottoPrimaryId)
    if XTool.IsNumberValid(curSelectLottoId) then
        self:Close()
        return
    end

    self:RefreshDynamicTable()
    XSaveTool.SaveData("OpenUiLottoFashionSelfChoiceEntrance", {NextCanShowTimeStamp = XTime.GetSeverTomorrowFreshTime()})
end

function XUiLottoFashionSelfChoiceEntrance:RefreshDynamicTable()
    local dataList = self.LottoPrimaryCfg.LottoIdList
    self.DynamicTable:SetDataSource(dataList)
    self.DynamicTable:ReloadDataSync()
end

---@param event any
---@param index any
---@param grid XUiDTGridLottoSelect
function XUiLottoFashionSelfChoiceEntrance:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local lottoId = self.DynamicTable.DataSource[index]
        grid:Refresh(lottoId, index)
        if self.CurSelectGridIndex == index then
            if self.CurSelectGrid then
                self.CurSelectGrid:SetUnSelect()
            end
            self.CurSelectGrid = grid
            self.CurSelectGridIndex = index

            grid:SetSelect()
            self:OnGridSelect(index, lottoId, grid)
        else
            grid:SetUnSelect()
        end
    -- 点击由Btn的回调去处理
    end
end

function XUiLottoFashionSelfChoiceEntrance:OnGridSelect(index, lottoId, grid)
    if self.CurSelectLottoId == lottoId then
        self.CurSelectGrid:SetSelect()
        return
    end
    self.CurSelectLottoId = lottoId

    -- 格子被选中后的切换逻辑
    self:PlayAnimation("QieHuan")

    -- 同步其他ui显示的信息的逻辑
    ---@type XTableLottoFashionSelfChoiceResources
    local lottoResConfig = XLottoConfigs.GetAllConfigs(XLottoConfigs.TableKey.LottoFashionSelfChoiceResources)[lottoId]
    self.VideoPlayer:SetInfoByVideoId(lottoResConfig.VideoConfigId)
    self.VideoPlayer:RePlay()

    local fashionId = lottoResConfig.SpecialRewardTemplateIds[1] -- 第1个默认是涂装id(写死)
    local fashionConfig = XFashionConfigs.GetFashionTemplate(fashionId)
    local characterId = fashionConfig.CharacterId
    self.TxtCharacterName.text = XMVCA.XCharacter:GetCharacterFullNameStr(characterId)
    self.TxtFashionName.text = fashionConfig.Name

    -- 奖励
    local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
    for k, templateId in ipairs(lottoResConfig.SpecialRewardTemplateIds) do
        local grid = self.GridRewardDic[k]
        if not grid then
            local ui = (k == 1) and self.Grid256New or XUiHelper.Instantiate(self.Grid256New, self.Grid256New.parent)
            grid = XUiGridCommon.New(self, ui)
            self.GridRewardDic[k] = grid
        end

        grid:Refresh({ TemplateId = templateId })
    end
end

function XUiLottoFashionSelfChoiceEntrance:OnBtnChooseClick()
    ---@type XTableLottoFashionSelfChoiceResources
    local lottoResConfig = XLottoConfigs.GetAllConfigs(XLottoConfigs.TableKey.LottoFashionSelfChoiceResources)[self.CurSelectLottoId]
    -- 检测是否弹出弹窗提示
    XLuaUiManager.Open("UiLottoFashionSelfChoiceDialog", self.CurSelectLottoId, self.CurSelectGrid.IsAllRewardGet, function ()
        XDataCenter.LottoManager.LottoSelfChoiceSelectRequest(self.LottoPrimaryId, self.CurSelectLottoId, function ()
            XFunctionManager.SkipInterface(lottoResConfig.SkipId)
        end)
    end)
end