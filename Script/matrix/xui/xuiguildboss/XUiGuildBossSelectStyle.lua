--公会boss选择风格流派
local XUiGuildBossSelectStyle = XLuaUiManager.Register(XLuaUi, "UiGuildBossSelectStyle")
local XUiGuildBossStyleGrid = require("XUi/XUiGuildBoss/Component/XUiGuildBossStyleGrid")
local XUiGuildBossStyleSkillGrid = require("XUi/XUiGuildBoss/Component/XUiGuildBossStyleSkillGrid")

function XUiGuildBossSelectStyle:OnAwake()
    self:AutoAddListener()
    self.WindowMode = 
    {
        Select = 1, -- 风格选择模式
        StyleDetail = 2, -- 风格详情模式
    }
    self.ScrollRectSeletStyle = self.InfoSelectList.gameObject:GetComponent("ScrollRect")
end

function XUiGuildBossSelectStyle:AutoAddListener()
    self.BtnTanchuangClose.CallBack = function() self:Close() end
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnChangeStyle.CallBack = function() self:OnBtnChangeStyleClick() end
    self.BtnResetSkill.CallBack = function() self:OnBtnResetSkillClick() end
end

function XUiGuildBossSelectStyle:OnStart()
    self.AllStyleConfig = XGuildBossConfig.GetGuildBossFightStyle() -- 所有的风格数据
    self:InitDynamicTable()

    XEventManager.AddEventListener(XEventId.EVENT_GUILDBOSS_STYLE_CHANGED, self.RefreshData, self)
end

function XUiGuildBossSelectStyle:OnEnable()
    -- 默认打开选择风格界面
    self.CurWindowMode = nil
    self:OpenWithWindowMode(self.WindowMode.Select)
    -- 刷新选择列表
    self.DynamicTableA:SetDataSource(self.AllStyleConfig)
    self.DynamicTableA:ReloadDataASync()
    -- 刷新
    self:RefreshData()

end

function XUiGuildBossSelectStyle:InitDynamicTable()
    -- 风格选择动态列表
    self.DynamicTableA = XDynamicTableNormal.New(self.InfoSelectList)
    self.DynamicTableA:SetProxy(XUiGuildBossStyleGrid, self)
    self.DynamicTableA:SetDelegate(self)
    self.DynamicTableA:SetDynamicEventDelegate(function (event, index, grid)
        self:OnDynamicTableEvent(event, index, grid, self.WindowMode.Select)
    end)
    self.GridBtn.gameObject:SetActiveEx(false)

    -- 技能动态列表
    self.DynamicTableB = XDynamicTableNormal.New(self.PanelSkillList)
    self.DynamicTableB:SetProxy(XUiGuildBossStyleSkillGrid, self)
    self.DynamicTableB:SetDelegate(self)
    self.DynamicTableB:SetDynamicEventDelegate(function (event, index, grid)
        self:OnDynamicTableEvent(event, index, grid, self.WindowMode.StyleDetail)
    end)
    self.GridSkill.gameObject:SetActiveEx(false)
end

function XUiGuildBossSelectStyle:OnDynamicTableEvent(event, index, grid, windowMode)
    -- 用windowMode区分两个动态列表
    if windowMode == self.WindowMode.Select then --风格选择动态列表
        if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
            grid.RootUi = self
        elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
            local styleConfig = self.AllStyleConfig[index]
            grid:Init(styleConfig, styleConfig.Id == self.CurrStyleId)
        elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        end
    elseif windowMode == self.WindowMode.StyleDetail then --风格详情里的技能动态列表
        if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
            grid.RootUi = self
        elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
            local styleSkillConfig = self.AllSkills[index]
            grid:Init(styleSkillConfig, table.contains(self.AllSelectSkill, styleSkillConfig.Id), styleSkillConfig.Style == self.CurrStyleId)
        elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        end
    end
end

-- 打开风格详情
function XUiGuildBossSelectStyle:OpenStyleDetailWithPlayScroll(styleId)
    -- 通过切换windowMode打开详情
    self:OpenWithWindowMode(self.WindowMode.StyleDetail)
    -- 刷新数据
    self:RefreshOpenStyleDetail(styleId)
    -- 播放动画
    self:PlayAnimation("InfoSkillEnable")
end

-- 刷新数据
function XUiGuildBossSelectStyle:RefreshData()
    -- 获取服务器下发的数据
    self.FightStyle = XDataCenter.GuildBossManager.GetFightStyle()
    self.CurrStyleId = self.FightStyle.StyleId
    self.AllSelectSkill = self.FightStyle.EffectedSkillId
    
    -- 刷新风格详情界面，如果没有选择风格详情则默认刷新第一个风格
    self:RefreshOpenStyleDetail(self.CurrShowStyleId or 1)
end

-- 详情并刷新界面
function XUiGuildBossSelectStyle:RefreshOpenStyleDetail(styleId)
    -- 刷新详情里的技能列表
    self.AllConfig = XGuildBossConfig.GetGuildStyleSkillByStyle(styleId) -- 拿到这个风格所有的技能
    self.AllSkills = {}
    for _, v in pairs(self.AllConfig) do -- 下标必须从1开始 所以要重新insert一遍表
        table.insert(self.AllSkills, v)
    end
    table.sort(self.AllSkills, function (a,b) -- 按照Id排序
        return a.Id < b.Id
    end)

    -- 当前风格选择技能的个数
    self.AllSelectSkill = self.FightStyle.EffectedSkillId
    local activeSkillNum = (styleId == self.CurrStyleId) and #self.AllSelectSkill or 0
    self.TxtSkillNum.text = "("..activeSkillNum .. "/" .. self.AllStyleConfig[styleId].MaxCount..")"

    -- 刷新动态列表
    self.DynamicTableB:SetDataSource(self.AllSkills)
    self.DynamicTableB:ReloadDataASync()

    -- 打开计时器，倒计时中按钮置灰不可显示
    self.IsChangeStyleEnable = false
    -- 未选择风格时则正常显示，且按钮名为选择流派
    if not self.CurrStyleId or self.CurrStyleId <= 0 then
        self.IsChangeStyleEnable = true
    end

    local leftTimePre = self.FightStyle.LastEffectTime + CS.XGame.Config:GetInt("GuildFightStyleCd") - XTime.GetServerNowTimestamp()
    self.TxtBtnTime.gameObject:SetActiveEx(styleId ~= self.CurrStyleId)
    self.TxtTime.gameObject:SetActiveEx(leftTimePre > 0 and self.CurWindowMode == self.WindowMode.Select)
    self.Timer = XScheduleManager.ScheduleForever(function()
        if XTool.UObjIsNil(self.TxtTime) then self:RemoveTimer() return end 
        local leftTime = self.FightStyle.LastEffectTime + CS.XGame.Config:GetInt("GuildFightStyleCd") - XTime.GetServerNowTimestamp()
        if leftTime <= 0 then
            self.TxtTime.gameObject:SetActiveEx(false)
            self.TxtBtnTime.gameObject:SetActiveEx(false)
            
            if styleId ~= self.CurrStyleId then
                self.IsChangeStyleEnable = true
                self.BtnChangeStyle:SetDisable(not self.IsChangeStyleEnable)
                self.BtnChangeStyle:SetName(styleId == self.CurrStyleId and CS.XTextManager.GetText("GuildBossStyleSelected") or CS.XTextManager.GetText("GuildBossStyleWarningGoSelect"))
            end
            
            self:RemoveTimer()
        end
        self.TxtTime.text = CSXTextManagerGetText("GuildBossStyleChangeTime", XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.DEFAULT))
        self.TxtBtnTime.text = CSXTextManagerGetText("GuildBossStyleChangeTime", XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.DEFAULT))
    end, 1)

    self.BtnChangeStyle:SetDisable(not self.IsChangeStyleEnable)
    self.BtnChangeStyle:SetName(styleId == self.CurrStyleId and CS.XTextManager.GetText("GuildBossStyleSelected") or CS.XTextManager.GetText("GuildBossStyleWarningGoSelect"))
    self.BtnResetSkill.gameObject:SetActiveEx(styleId == self.CurrStyleId and activeSkillNum > 0)

    -- 当前查看的风格
    self.BtnStyle:SetRawImage(self.AllStyleConfig[styleId].Bg)
    self.BtnStyle.transform:Find("CurMark").gameObject:SetActiveEx(styleId == self.CurrStyleId)

    self.CurrShowStyleId = styleId
end

-- 根据WindowMode切换界面
function XUiGuildBossSelectStyle:OpenWithWindowMode(windowMode)
    if windowMode == self.CurWindowMode then
        return
    end

    if windowMode == self.WindowMode.Select then
        self.Shelter.gameObject:SetActiveEx(false)
        self.InfoSelect.gameObject:GetComponent("CanvasGroup").blocksRaycasts = true
        self.InfoSkill.gameObject:GetComponent("CanvasGroup").blocksRaycasts = false
    elseif windowMode == self.WindowMode.StyleDetail then
        self.Shelter.gameObject:SetActiveEx(true)
        self.InfoSelect.gameObject:GetComponent("CanvasGroup").blocksRaycasts = false
        self.InfoSkill.gameObject:GetComponent("CanvasGroup").blocksRaycasts = true
    end
    self.CurWindowMode = windowMode
end

-- 选择后滑动(暂时弃用)
function XUiGuildBossSelectStyle:PlayScrollViewMove(grid, cb)
    -- 打开详情后不能滑动下层的列表
    self:SetSelectStyleMovementType(CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted)
    local gridRect = grid:GetComponent("RectTransform")
    local diffX = gridRect.localPosition.x + self.StyleSelectContent.localPosition.x
    if diffX < XDataCenter.FubenMainLineManager.UiGridChapterMoveMinX or diffX > XDataCenter.FubenMainLineManager.UiGridChapterMoveMaxX then
        local tarPosX = XDataCenter.FubenMainLineManager.UiGridChapterMoveTargetX * 1.23 - gridRect.localPosition.x
        local tarPos = self.StyleSelectContent.localPosition
        tarPos.x = tarPosX
        XLuaUiManager.SetMask(true)
        self.OrgTargetPosX = self.StyleSelectContent.localPosition.x
        XUiHelper.DoMove(self.StyleSelectContent, tarPos, XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration, XUiHelper.EaseType.Sin, function()
            XLuaUiManager.SetMask(false)
            if cb then
                cb()
            end
        end)
    end
end

-- 滑动返回去(暂时弃用)
function XUiGuildBossSelectStyle:PlayScrollViewBack(cb)
    -- 打开详情后不能滑动下层的列表
    self:SetSelectStyleMovementType(CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted)
    local tarPosX = self.OrgTargetPosX
    local tarPos = self.StyleSelectContent.localPosition
    tarPos.x = tarPosX
    XLuaUiManager.SetMask(true)
    XUiHelper.DoMove(self.StyleSelectContent, tarPos, XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration, XUiHelper.EaseType.Sin, function()
        XLuaUiManager.SetMask(false)
        if cb then
            cb()
        end
    end)
end

-- 滑动时设为非弹性(切为详情模式时),选择模式切回来
function XUiGuildBossSelectStyle:SetSelectStyleMovementType(moveMentType)
    if not self.ScrollRectSeletStyle then return end
    self.ScrollRectSeletStyle.movementType = moveMentType
end

-- 确定选择风格按钮
function XUiGuildBossSelectStyle:OnBtnChangeStyleClick()
    if not XFunctionManager.CheckInTimeByTimeId(CS.XGame.Config:GetInt("GuildBossThirdVersionTimeId")) then
        XUiManager.TipMsg(CS.XTextManager.GetText("GuildBossStyleSelectLimit"))
        return
    end

    if not self.IsChangeStyleEnable then return end
    -- 向服务器请求选择风格
    XNetwork.Call("GuildSelectFightStyleRequest", {StyleId = self.CurrShowStyleId}, function(reply)
        if reply.Code ~= XCode.Success then
            XUiManager.TipCode(reply.Code)
        end
        XUiManager.TipMsg(CS.XTextManager.GetText("GuildBossStyleSelectSucceess"))
        -- 在这里给选择成功的风格打上标签，因为如果用动态列表的reload刷新会使列表重置改变滑动的模式为弹性，导致除当前选择的风格grid也会出现
        self.DynamicTableA:GetGridByIndex(self.CurrShowStyleId):SetCurMask(true)
        -- 风格选择成功后要再向服务器拿一遍数据
        XDataCenter.GuildBossManager.GuildBossStyleInfoRequest(function ()
            self:RefreshData()
        end)
    end)
end

-- 重置所有激活的技能（卸载）
function XUiGuildBossSelectStyle:OnBtnResetSkillClick()
    XDataCenter.GuildBossManager.GuildBossStyleSkillChangeRequeset(GuildBossStyleSkillChangeType.Reset, nil, function ()
        XUiManager.TipMsg(CS.XTextManager.GetText("GuildBossStyleSkillAllUninstall"))
    end)
end

function XUiGuildBossSelectStyle:OnBtnBackClick()
    self:OpenWithWindowMode(self.WindowMode.Select)
    -- 刷新选择列表
    self.DynamicTableA:SetDataSource(self.AllStyleConfig)
    self.DynamicTableA:ReloadDataASync()
    self:RefreshData()
    -- 播放动画
    self:PlayAnimation("InfoSkillDisable")
end

function XUiGuildBossSelectStyle:RemoveTimer()
    if not self.Timer then return end
    XScheduleManager.UnSchedule(self.Timer)
    self.Timer = nil
end

function XUiGuildBossSelectStyle:OnDisable()
    self:RemoveTimer()
end

function XUiGuildBossSelectStyle:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDBOSS_STYLE_CHANGED, self.RefreshData, self)

end