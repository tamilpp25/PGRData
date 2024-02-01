---@class XUiMail : XLuaUi
---@field _Control XMailControl
local XUiMail = XLuaUiManager.Register(XLuaUi, "UiMail")
local XUiGridTitle = require("XUi/XUiMail/XUiGridTitle") --XUiGridTitle,
--local XUiGridItem = require("XUi/XUiMail/XUiGridItem") --XUiGridItem,
local MailMaxCount = CS.XGame.Config:GetInt("MailCountLimit")
local CSGetText = CS.XTextManager.GetText
function XUiMail:OnAwake()
    self:InitAutoScript()

    self.DynamicTable = XDynamicTableNormal.New(self.PanelTitleList)
    self.DynamicTable:SetProxy(XUiGridTitle)
    self.DynamicTable:SetDelegate(self)
    self.GridTitle.gameObject:SetActive(false)
    self:AddRedPointEvent(self.RedCollection, self.OnCheckCollectionBoxView, self, { XRedPointConditions.Types.CONDITION_MAIL_FAVORITE_BOX })
end

function XUiMail:OnStart()
    self.CurMailInfo = nil
    self.SelectTitle = nil
    self.UpdateTimer = nil
    self.ExpireCache = {}
    self.RewardGrids = {}

    self.HtmlText = self.GridContent:GetComponent("XHtmlText")
    self.HtmlTextNotReward = self.GridContentNotReward:GetComponent("XHtmlText")
    self.HtmlText.HrefListener = function(link)
        self:ClickLink(link)
    end
    self.HtmlTextNotReward.HrefListener = function(link)
        self:ClickLink(link)
    end
    

    self:Reset()

    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    -- local musicKey = self:GetAutoKey(self.BtnBack, "onClick")
    -- self.SpecialSoundMap[musicKey] = XSoundManager.UiBasicsMusic.Return
end

function XUiMail:OnEnable()
    self.CollectionEffect.gameObject:SetActiveEx(false)--解决UI启动时特效重复播放问题
    self:ReLoadMailData(false)
    self.UpdateTimer = XScheduleManager.ScheduleForever(Handler(self, self.Update), XScheduleManager.SECOND)
end

function XUiMail:OnDisable()
    self:RemoveTimer()
    self:RemoveUpdateTimer()
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiMail:InitAutoScript()
    self:AutoAddListener()
end

--动态列表事件
function XUiMail:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateMailGrid(self,self.PageDatas[index])
    end
end

function XUiMail:SetupDynamicTable(IsNotSync)
    if not IsNotSync then
        self.PageDatas = self._Control:GetMailList()
    end
    
    self.ExpireCache = {}
    for _, mailInfo in pairs(self.PageDatas) do
        if not XMVCA.XMail:IsExpireAndReserve(mailInfo.Id) then
            self.ExpireCache[mailInfo.Id] = true
        end
    end
    self.CurMailInfo = self.PageDatas[1]
    self.DynamicTable:SetDataSource(self.PageDatas)
    self.DynamicTable:ReloadDataSync(1)
end

function XUiMail:AutoAddListener()
    self.BtnDelete.CallBack = function()
        self:OnBtnDeleteClick()
    end
    self.BtnGet.CallBack = function()
        self:OnBtnGetClick()
    end
    self.BtnGetReward.CallBack = function()
        self:OnBtnGetRewardClick()
    end
    self.BtnCollection.CallBack = function()
        self:OnBtnCollectionClick()
    end
    self.BtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end

end
-- auto

function XUiMail:Reset()
    self.PanelMailContent.gameObject:SetActive(false)
    --self.ImgBgUn.gameObject:SetActive(true)
    self.BtnGetReward.gameObject:SetActive(false)
    self.BtnGetReward:SetButtonState(CS.UiButtonState.Normal)
    self.ImgGetReward.gameObject:SetActive(false)
    self.PanelItemContent.gameObject:SetActive(false)
end

function XUiMail:ReLoadMailData(IsNotSync)
    self:SetupDynamicTable(IsNotSync)
    self:UpdateMailList()
end

function XUiMail:ResetReward()
    if self.CurMailInfo and self.CurMailInfo.Id then
        self:Reset()
        if self.CurMailInfo.MailType == XEnumConst.MailType.Normal then
            self:SetRewardBtnStatusNormal(self.CurMailInfo.Id)
            self:InitRewardListNormal(self.CurMailInfo)
        elseif self.CurMailInfo.MailType == XEnumConst.MailType.FavoriteMail then
            self:SetRewardBtnStatusFavorite(self.CurMailInfo.Id)
            self:InitRewardListFavorite(self.CurMailInfo)
        end
    end
end

--更新邮件列表
function XUiMail:UpdateMailList()
    self.PanelUnGet.gameObject:SetActive(false)
    self.TxtMailCount.text = CSGetText("MailCountText",#self.PageDatas,MailMaxCount)
    if #self.PageDatas == 0 then
        self:ClickMailGrid(nil)
        return
    end
end
--=========点击邮件 更新内容显示==========
function XUiMail:ClickMailGrid(mailInfo,IsPlayAnim)
    if mailInfo == nil then
        self:ShowMailInfoNone()
        return
    end
    if mailInfo.MailType == XEnumConst.MailType.Normal then
        self:ClickMailGridNormal(mailInfo,IsPlayAnim)
    elseif mailInfo.MailType == XEnumConst.MailType.FavoriteMail then
        self:ClickMailGridFavorite(mailInfo,IsPlayAnim)
    end
end
--更新普通邮件视图
function XUiMail:ClickMailGridNormal(mailInfo,IsPlayAnim)
    --self.ImgBgUn.gameObject:SetActive(false)
    self._Control:ReadMail(mailInfo.Id)
    self:ShowMailInfoNormal(mailInfo)
    self:SetRewardBtnStatusNormal(mailInfo.Id)
    self:InitRewardListNormal(mailInfo)
    if IsPlayAnim then
        self:PlayAnimation("AnimYouJianEnable")
    end
end
--更新收藏角色好感邮件视图
function XUiMail:ClickMailGridFavorite(mailInfo,IsPlayAnim)
    self._Control:ReadFavoriteMail(mailInfo.Id)
    self:ShowMailInfoFavorite(mailInfo)
    self:SetRewardBtnStatusFavorite(mailInfo.Id)
    self:InitRewardListFavorite(mailInfo)
    if IsPlayAnim then
        self:PlayAnimation("AnimYouJianEnable")
    end
end
--=========点击邮件 更新内容显示==========

--=========更新邮件内容===========
--显示无邮件内容
function XUiMail:ShowMailInfoNone()
    self.PanelUnGet.gameObject:SetActive(true)
    self.PanelMailContent.gameObject:SetActive(false)
end
--显示普通邮件内容
function XUiMail:ShowMailInfoNormal(mailInfo)
    self.TxtContentTitle.text = mailInfo.Title
    local content = mailInfo.Content or ""
    local sendName = mailInfo.SendName or ""

    --- 退款封禁邮件日期换行问题，替换空格编码
    if mailInfo.Type == XEnumConst.MailType.SpecialMail then
        content = XUiHelper.ReplaceUnicodeSpace(content)
    end

    --问卷需要对正文进行处理显示超链接
    if mailInfo.IsSurvey then
        content = self._Control:FixSurveyContent(mailInfo)
    end
    
    if self._Control:HasMailReward(mailInfo.Id) then
        self.PanelContent.gameObject:SetActiveEx(true)
        self.PanelExpire.gameObject:SetActiveEx(false)
        self.PanelContentReward.gameObject:SetActiveEx(true)
        self.HtmlText.text = content .. "\n\n" .. CSGetText("ComeFrom") .. ": " .. sendName .. "\n"
    else
        self.PanelContent.gameObject:SetActiveEx(false)
        self.PanelExpire.gameObject:SetActiveEx(true)
        self.PanelContentReward.gameObject:SetActiveEx(false)
        self.HtmlTextNotReward.text = content .. "\n\n" .. CSGetText("ComeFrom") .. ": " .. sendName .. "\n"
    end
    
    self.PanelMailContent.gameObject:SetActive(true)
    self:RemoveTimer()

    if not mailInfo.ExpireTime then
        self.TxtContentDateNum.gameObject:SetActive(false)
        return
    end

    self.TxtForbidDelete.gameObject:SetActiveEx(mailInfo.IsForbidDelete)

    ---@type XMailAgency
    local mailAgency = XMVCA:GetAgency(ModuleId.XMail)
    local refreshFunc = nil
    if not mailAgency:IsExpire(mailInfo.Id) then
        local restTime = mailInfo.ExpireTime - XTime.GetServerNowTimestamp()
        
        refreshFunc = function()
            local dataTime = XUiHelper.GetTime(math.max(restTime, 0))
            
            if XTool.UObjIsNil(self.TxtContentDateNum) then
                return
            end
            self.TxtContentDateNum.text = CSGetText("EmailExpireTime",dataTime)
            restTime = restTime - 1

            if restTime < 0 then
                refreshFunc = nil
            end
        end
    elseif mailAgency:IsExpireAndReserve(mailInfo.Id) then 
        local restTime = mailInfo.ReserveTime - XTime.GetServerNowTimestamp()

        refreshFunc = function()
            local dataTime = XUiHelper.GetTime(math.max(restTime, 0))
            if XTool.UObjIsNil(self.TxtContentDateNum) then
                return
            end
            self.TxtContentDateNum.text = CSGetText("EmailExpireTime",dataTime)
            restTime = restTime - 1
            
            if restTime < 0 then
                refreshFunc = nil
            end
        end
    else
        if mailInfo.ExpireTime == 0 then
            self.TxtContentDateNum.text = CSGetText("EmailForever")
        else
            self.TxtContentDateNum.text = CSGetText("EmailExpireTime",XUiHelper.GetTime(0))
        end

    end

    if refreshFunc then
        refreshFunc()
    else
        return
    end

    self.Timer = XScheduleManager.ScheduleForever(function()
        if not refreshFunc then
            self:RemoveTimer()
            return
        end

        if refreshFunc then
            refreshFunc()
        end
    end, 1000)
end
--显示收藏角色好感邮件内容
function XUiMail:ShowMailInfoFavorite(mailInfo)
    local mailData = mailInfo.MailData
    self.TxtContentTitle.text = mailData.Title
    local content = mailData.Content or ""
    local sendName = mailData.SendName or ""

    if not XTool.IsTableEmpty(mailData.RewardIds) then
        self.PanelContent.gameObject:SetActiveEx(true)
        self.PanelExpire.gameObject:SetActiveEx(false)
        self.PanelContentReward.gameObject:SetActiveEx(true)
        self.HtmlText.text = XUiHelper.ConvertLineBreakSymbol(content) .. "\n\n" .. CSGetText("ComeFrom") .. ": " .. sendName .. "\n"
    else
        self.PanelContent.gameObject:SetActiveEx(false)
        self.PanelExpire.gameObject:SetActiveEx(true)
        self.PanelContentReward.gameObject:SetActiveEx(false)
        self.HtmlTextNotReward.text = XUiHelper.ConvertLineBreakSymbol(content) .. "\n\n" .. CSGetText("ComeFrom") .. ": " .. sendName .. "\n"
    end

    self.PanelMailContent.gameObject:SetActive(true)
    self:RemoveTimer()
    if not mailInfo.ExpireTime then
        self.TxtContentDateNum.gameObject:SetActive(false)
        return
    end
    self.TxtForbidDelete.gameObject:SetActiveEx(true)

    local refreshFunc
    local restTime = mailInfo.ExpireTime - XTime.GetServerNowTimestamp()
    if restTime and restTime > 0 then
        refreshFunc = function ()
            local dataTime = XUiHelper.GetTime(restTime)
            if XTool.UObjIsNil(self.TxtContentDateNum) then
                return
            end
            self.TxtContentDateNum.text = CSGetText("EmailExpireTime",dataTime)
            restTime = restTime - 1

            if restTime < 0 then
                refreshFunc = nil
            end
        end
    else
        if mailInfo.ExpireTime == 0 then
            self.TxtContentDateNum.text = CSGetText("EmailForever")
        else
            self.TxtContentDateNum.text = CSGetText("EmailExpireTime",XUiHelper.GetTime(0))
        end

    end

    if refreshFunc then
        refreshFunc()
    else
        return
    end

    self.Timer = XScheduleManager.ScheduleForever(function()
        if not refreshFunc then
            self:RemoveTimer()
            return
        end

        if refreshFunc then
            refreshFunc()
        end
    end, 1000)
end
--=========更新邮件内容===========

--=========更新邮件奖励列表===========
--显示普通邮件奖励内容
function XUiMail:InitRewardListNormal(mailInfo)
    local mailId = mailInfo.Id
    local baseItem = self.GridItem
    baseItem.gameObject:SetActive(false)
    self.PanelItemContent.gameObject:SetActive(false)

    if not self._Control:HasMailReward(mailId) then
        return
    end

    self.PanelContentReward.gameObject:SetActiveEx(true)
    for _, grid in pairs(self.RewardGrids) do
        grid:Refresh()
    end

    ---@type XMailAgency
    local mailAgency = XMVCA:GetAgency(ModuleId.XMail)
    local mail = self._Control:GetMailCache(mailId)
    local isGetReward = mailAgency.IsGetReward(mail.Status)
    local index = 1
    local function refreshReward(value)
        if not self.RewardGrids[index] then
            local item = CS.UnityEngine.Object.Instantiate(baseItem)
            local grid = XUiGridCommon.New(self, item)
            grid.Transform:SetParent(self.PanelItemContent, false)
            self.RewardGrids[index] = grid
        end

        self.RewardGrids[index]:Refresh(value, { ["ShowReceived"] = isGetReward })
        index = index + 1
    end

    local rewards = XRewardManager.MergeAndSortRewardGoodsList(mail.RewardGoodsList)
    for i = 1, #rewards do
        refreshReward(rewards[i])
    end

    self.PanelItemContent.gameObject:SetActive(true)
end
--显示收藏角色好感邮件内容
function XUiMail:InitRewardListFavorite(mailInfo)
    local mailData = mailInfo.MailData
    local baseItem = self.GridItem
    baseItem.gameObject:SetActive(false)
    self.PanelItemContent.gameObject:SetActive(false)
    if #mailData.RewardIds == 0 then return end
    self.PanelContentReward.gameObject:SetActiveEx(true)
    for _, grid in pairs(self.RewardGrids) do
        grid:Refresh()
    end
    local isGetReward = not (self._Control:HasFavoriteMail(mailInfo.Id) == false)
    local index = 1
    local function refreshReward(value)
        if not self.RewardGrids[index] then
            local item = CS.UnityEngine.Object.Instantiate(baseItem)
            local grid = XUiGridCommon.New(self, item)
            grid.Transform:SetParent(self.PanelItemContent, false)
            self.RewardGrids[index] = grid
        end
        self.RewardGrids[index]:Refresh(value, { ["ShowReceived"] = isGetReward })
        index = index + 1
    end

    local rewardList = {}
    for _,v in pairs(mailData.RewardIds) do
        local rDatas  = XRewardManager.GetRewardList(v)
        for _,reward in pairs(rDatas) do
            table.insert(rewardList,reward)
        end
    end
    
    for i = 1, #rewardList do
        refreshReward(rewardList[i])
    end

    self.PanelItemContent.gameObject:SetActive(true)
end
--=========更新邮件奖励列表===========

--=========更新领取按钮状态===========
function XUiMail:SetRewardBtnStatusNormal(mailId)
    mailId = mailId and mailId or self.CurMailInfo.Id
    self.BtnGetReward.gameObject:SetActive(false)
    self.ImgGetReward.gameObject:SetActive(false)

    if not mailId then
        return
    end

    local mail = self._Control:GetMailCache(mailId)
    if mail and self._Control:HasMailReward(mailId) then
        ---@type XMailAgency
        local mailAgency = XMVCA:GetAgency(ModuleId.XMail)

        if mailAgency:IsExpireAndReserve(mailId) then
            self.BtnGetReward.gameObject:SetActive(true)
            self.BtnGetReward:SetButtonState(CS.UiButtonState.Disable)
            self.BtnGetReward:SetNameByGroup(0, XUiHelper.GetText("MailInvalidation"))
        else
            if not mailAgency.IsGetReward(mail.Status) then
                self.BtnGetReward.gameObject:SetActive(true)
                self.BtnGetReward:SetButtonState(CS.UiButtonState.Normal)
                self.BtnGetReward:SetNameByGroup(0, XUiHelper.GetText("MailCanReceive"))
            else
                self.ImgGetReward.gameObject:SetActive(true)
            end
        end 
    end
end
function XUiMail:SetRewardBtnStatusFavorite(mailId)
    self.BtnGetReward.gameObject:SetActive(true)
    self.BtnGetReward:SetButtonState(CS.UiButtonState.Normal)
    self.ImgGetReward.gameObject:SetActive(false)
end
--=========更新领取按钮状态===========

--更新收藏盒红点状态
function XUiMail:OnCheckCollectionBoxView(count)
    self.RedCollection.gameObject:SetActiveEx(count > 0)
end

function XUiMail:OnBtnDeleteClick()
    self._Control:DeleteMail(function()
        self:ResetReward()
        self:ReLoadMailData(false)
        if self.TxtForbidDelete.gameObject.activeSelf then
            XUiManager.TipMsg(CsXTextManagerGetText("MailCantManulDelete"))
        end
    end)
end

function XUiMail:OnBtnGetClick()
    self._Control:GetAllMailReward(function(result)
        self:ResetReward()
        self:ReLoadMailData(false)
        if #result.CollectBoxMail > 0 then
            self:PlayAnimationWithMask("ImgMail2Enable")
        end
    end)
end

--领取奖励按钮响应
function XUiMail:OnBtnGetRewardClick()
    if self.BtnGetReward.ButtonState == CS.UiButtonState.Disable then
        return
    end
    if self.CurMailInfo then
        if self.CurMailInfo.MailType == XEnumConst.MailType.Normal then
            self._Control:GetMailReward(self.CurMailInfo.Id, function()
                self:ResetReward()
                if self.GetItemCallBack then
                    self.GetItemCallBack()
                end
                self:ClickMailGrid(self.CurMailInfo,true)
            end)
        elseif self.CurMailInfo.MailType == XEnumConst.MailType.FavoriteMail then
            self._Control:RequestReceivedFavoriteMails({ self.CurMailInfo.Id},function(success)
                self:ReLoadMailData(false)
                if success then
                    self:PlayAnimationWithMask("ImgMail2Enable")
                end
            end)
        end
    end
end

function XUiMail:OnBtnBackClick()
    self._Control:SyncMailEvent()
    self:Close()
end

function XUiMail:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiMail:OnBtnCollectionClick()
    XLuaUiManager.Open("UiFavoriteMailTag")
end

function XUiMail:SetRewardStatus(mailId)
    mailId = mailId and mailId or self.CurMailInfo.Id

    if not mailId then
        return
    end

    if self._Control:HasMailReward(mailId) then
        self.PanelItemContent.gameObject:SetActive(true)
        local isGetReward = self._Control:IsMailGetReward(mailId)
        for _, grid in pairs(self.RewardGrids) do
            grid:SetReceived(isGetReward)
        end
    end
end

function XUiMail:ClickLink(url)
    CS.UnityEngine.Application.OpenURL(url)
end

function XUiMail:RemoveTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiMail:Update()
    if not XTool.IsTableEmpty(self.PageDatas) then
        for _, mailInfo in pairs(self.PageDatas) do
            if self.ExpireCache[mailInfo.Id] and XMVCA.XMail:IsExpireAndReserve(mailInfo.Id) then
                self.ExpireCache[mailInfo.Id] = nil
                self:ReLoadMailData(false)
                break
            end
        end
    end 
end

function XUiMail:RemoveUpdateTimer()
    if self.UpdateTimer then
        XScheduleManager.UnSchedule(self.UpdateTimer)
        self.UpdateTimer = nil
    end    
end
