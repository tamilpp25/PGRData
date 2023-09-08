local XUiFavorabilityStory=XLuaUiManager.Register(XLuaUi,"UiFavorabilityStory")
local XUiGridFavorabilityStory=require('XUi/XUiFavorability/StoryPanel/XUiGridFavorabilityStory')
local Sequence={
    First=0,
    Mid=1,
    Last=2
}

local lastPosX=0 --上一次关闭前content的x坐标
local shouldResume=false

--region 生命周期
function XUiFavorabilityStory:OnAwake()
    self:InitCb()
end

function XUiFavorabilityStory:OnStart(currentCharacterId)
    self.CurrentCharacterId=currentCharacterId
    self:RefreshList()
    self:RefreshBaseData()
    self:RefreshStoryData()
end
--endregion

--region 初始化
function XUiFavorabilityStory:InitCb()
    self.BtnBack.CallBack=function() self:Close() end
    self.BtnMainUi.CallBack=function() XLuaUiManager.RunMain() end
end
--endrgion

--region 数据更新
function XUiFavorabilityStory:RefreshList()
    local config=self._Control:GetStoryLayout(self.CurrentCharacterId)
    self.FavorabilityStoryStage=self.PanelChapter:LoadPrefab(config.LayOutType)
    self.StoryGridCtrls={}
    XTool.InitUiObjectByUi(self,self.FavorabilityStoryStage)
    local needResume=self:IsTriggerReusme()
    for i=1,15 do
        if self['GridStoryStage'..i] then
            table.insert(self.StoryGridCtrls,XUiGridFavorabilityStory.New(self['GridStoryStage'..i],self))
            if not self.StoryContent then
                self.StoryContent=self['GridStoryStage'..i].transform.parent
            end
            if needResume then
                needResume=false
                self.StoryContent.anchoredPosition =Vector2(lastPosX,self.StoryContent.anchoredPosition.y)
            end
        end
    end
end

function XUiFavorabilityStory:RefreshBaseData()
    --self.TxtName.text=XUiHelper.GetText('FavorabilityStoryCharName',XMVCA.XCharacter:GetCharacterName(self.CurrentCharacterId),XMVCA.XCharacter:GetCharacterTradeName(self.CurrentCharacterId))
    self.TxtName.text=XMVCA.XCharacter:GetCharacterLogName(self.CurrentCharacterId)
    --队伍图标
    local teamIcon=self._Control:GetCharacterTeamIconById(self.CurrentCharacterId)
    if teamIcon then
        self.RImgTeamIcon:SetRawImage(teamIcon)
    else
        --读默认的透明图片
        self.RImgTeamIcon:SetRawImage(CS.XGame.ClientConfig:GetString("TrustNoData"))
    end
end

function XUiFavorabilityStory:RefreshStoryData()
    --隐藏格子和线条
    for i=1,15 do
        if self['GridStoryStage'..i] then
            self['GridStoryStage'..i].gameObject:SetActiveEx(false)
        end
        if self['Line'..i] then
            self['Line'..i].gameObject:SetActiveEx(false)
        end
    end
    
    --显示和设置格子数据
    local plotDatas = XMVCA.XFavorability:GetCharacterStoryById(self.CurrentCharacterId)
    local dataCount=#plotDatas
    local firstOne=true
    for i, data in ipairs(plotDatas) do
        if data and self.StoryGridCtrls[i] then
            self.StoryGridCtrls[i]:Refresh(data)
            self['GridStoryStage'..i].gameObject:SetActiveEx(true)
            if firstOne then
                self.StoryGridCtrls[i]:SetSequence(Sequence.First)
                firstOne=false
            elseif i==dataCount then
                self.StoryGridCtrls[i]:SetSequence(Sequence.Last)
            else
                self.StoryGridCtrls[i]:SetSequence(Sequence.Mid)
            end
        end
    end

    --显示线条
    for i=1,dataCount-1 do
        if self['Line'..i] then
            self['Line'..i].gameObject:SetActiveEx(true)
        end
    end
    
    --显示解锁进度
    local unlockNum,storyNum=self._Control:StoryUnlockNum(self.CurrentCharacterId)
    self.TxtUnlockNum.text=tostring(unlockNum)
    self.TxtAllNum.text='/'..tostring(storyNum)
end
--endregion

--region 事件
function XUiFavorabilityStory:SetResumeTrigger(trigger)
    shouldResume=trigger
    if trigger then
        lastPosX=self.StoryContent.anchoredPosition.x
    end
end

function XUiFavorabilityStory:IsTriggerReusme()
    if shouldResume then
        shouldResume=false
        return true
    end
    return false
end
--endregion


return XUiFavorabilityStory

