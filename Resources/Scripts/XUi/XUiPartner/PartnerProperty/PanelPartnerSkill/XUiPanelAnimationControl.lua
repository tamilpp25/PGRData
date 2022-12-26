local XUiPanelAnimationControl = XClass(nil, "XUiPanelAnimationControl")
local FirstIndex = 1
local LastIndex = 6
function XUiPanelAnimationControl:Ctor(ui, base, root)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    self.Root = root
    XTool.InitUiObject(self)
    self:InitPanel()
end

function XUiPanelAnimationControl:InitPanel()
    self.RandomEnableAnimeList = {
        self.MainSkillAnime:GetObject("MainSkillPosEnable"),
        self.PassiveSkillAnime1:GetObject("PassiveSkillPosEnable"),
        self.PassiveSkillAnime2:GetObject("PassiveSkillPosEnable"),
        self.PassiveSkillAnime3:GetObject("PassiveSkillPosEnable"),
        self.PassiveSkillAnime4:GetObject("PassiveSkillPosEnable"),
        self.PassiveSkillAnime5:GetObject("PassiveSkillPosEnable")}

    self.RandomSelectedAnimeList = {
        self.MainSkillAnime:GetObject("ImgColor"),
        self.PassiveSkillAnime1:GetObject("ImgColor"),
        self.PassiveSkillAnime2:GetObject("ImgColor"),
        self.PassiveSkillAnime3:GetObject("ImgColor"),
        self.PassiveSkillAnime4:GetObject("ImgColor"),
        self.PassiveSkillAnime5:GetObject("ImgColor")}
end

function XUiPanelAnimationControl:UpdatePanel()
    self.RandomShowSkillAnimeList = {
        self.Base.SkillUpPanel.MainSkill.GridMainSkillEnable,
        self.Base.SkillUpPanel.PassiveSkillList[1].GridPassiveSkillEnable,
        self.Base.SkillUpPanel.PassiveSkillList[2].GridPassiveSkillEnable,
        self.Base.SkillUpPanel.PassiveSkillList[3].GridPassiveSkillEnable,
        self.Base.SkillUpPanel.PassiveSkillList[4].GridPassiveSkillEnable,
        self.Base.SkillUpPanel.PassiveSkillList[5].GridPassiveSkillEnable}
end

function XUiPanelAnimationControl:GetRandomNumList(firstIndex, lastIndex)
    local temp = {}
    local list = {}
    for i = 1, lastIndex - firstIndex + 1 do
        table.insert(list, firstIndex + i - 1)
    end
    for i = 1, lastIndex - firstIndex + 1 do
        local r = math.random(1, #list)
        temp[i] = list[r]
        table.remove(list, r)
    end
    return temp
end

function XUiPanelAnimationControl:SetEndNum(list, endNum)
    if not list then return end

    for index,num in pairs(list) do
        if num == endNum then
            table.remove(list, index)
            break
        end
    end

    table.insert(list,endNum)
end

function XUiPanelAnimationControl:PlaySkillUpAnime(endIndex, cb)
    math.randomseed(os.time())
    local randomIndexList = self:GetRandomNumList(FirstIndex, LastIndex)
    self:SetEndNum(randomIndexList, endIndex)

    coroutine.wrap(function()
            local co = coroutine.running()
            local callBack = function() coroutine.resume(co) end
            
            local count = 1
            local count_2_CallBack = function()
                if count >= 2 then
                    coroutine.resume(co)
                    count = 1
                    return
                end
                count = count + 1
            end
            XLuaUiManager.SetMask(true)
            self.ReadySkillUpRotate:PlayTimelineAnimation()
            
            for count,index in pairs(randomIndexList) do
                if count < #randomIndexList then
                    self.RandomEnableAnimeList[index]:PlayTimelineAnimation(callBack)
                    coroutine.yield()
                end
            end

            self.RandomSelectedAnimeList[endIndex]:PlayTimelineAnimation(count_2_CallBack)
            self.RandomShowSkillAnimeList[endIndex]:PlayTimelineAnimation(count_2_CallBack)
            coroutine.yield()
            
            XLuaUiManager.SetMask(false)
            if cb then cb() end
            
        end)()
end

function XUiPanelAnimationControl:PlaySelectAnime(index, cb)
    XLuaUiManager.SetMask(true)
    self.RandomEnableAnimeList[index]:PlayTimelineAnimation(function ()
            XLuaUiManager.SetMask(false)
            if cb then cb() end
    end)
end

return XUiPanelAnimationControl