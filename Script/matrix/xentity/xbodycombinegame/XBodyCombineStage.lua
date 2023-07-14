--===========================================================================
 ---@desc 哈卡玛拼图游戏-部分身体
--===========================================================================
local XBodyCombinePart = XClass(nil, "XBodyCombinePart")

function XBodyCombinePart:Ctor(data)
    self.Data = data or {}
    self.Index = 1 --起始位置
    self.CurData = { self.Data[1], self.Data[2], self.Data[3] } --当前展示的3个数据
    self.LastIndex = 1 --上次读取数据时，拿到的下标
    self.Length = #self.Data
end

function XBodyCombinePart:__Next(curIndex)
    local index = curIndex < self.Length and curIndex + 1 or 1
    return index
end

function XBodyCombinePart:__Last(curIndex)
    local index = curIndex > 1 and curIndex - 1 or self.Length
    return index
end

---==============================
   ---@desc:  循环列表->向后移动一位 
---==============================
function XBodyCombinePart:PlayNext()
    self.Index = self:__Next(self.Index)
end

---==============================
   ---@desc: 循环列表->向前移动一位 
---==============================
function XBodyCombinePart:PlayLast()
    self.Index = self:__Last(self.Index)
end

---==============================
   ---@desc: 当前部位的展示的数据，可能存在很多数据，只展示3个
---==============================
function XBodyCombinePart:GetCurData()
    if self.Index ~= self.LastIndex then
        local fir = self.Index
        local sec = self:__Next(fir)
        local thi = self:__Next(sec)
        self.CurData = { self.Data[fir], self.Data[sec], self.Data[thi] }
        self.LastIndex = self.Index
    end
    return self.CurData
end

---==============================
   ---@desc: 判断两个部位的数据是否一致
   ---@param: 另一个部位
   ---@return: bool
---==============================
function XBodyCombinePart:IsEqual(other)
    if not other then return false end
    
    local curData = self:GetCurData()
    local oerData = other:GetCurData()
    
    local dataLength = #curData
    
    for idx = 1, dataLength do
        local cur = curData[idx]
        local otr = oerData[idx]
        
        --等于0，则跳过检验
        if cur == 0 or otr == 0 then
            goto Continue
        end
        
        if cur ~= otr then
            return false
        end
        ::Continue::
    end
    return true
end

---==============================
   ---@desc: 接头霸王关卡类
---==============================
local XBodyCombineStage = XClass(nil, "XBodyCombineStage")

local default = {
    PreStage = 0,
    Desc = "",
    SuspectIcon = "",
    CostCount = 0,
    PassDesc = "",
    OpenBanner = "",
    FinishBanner = "",
    QuestionDescs = {},
    WinnerQIcon = ""
}

function XBodyCombineStage:Ctor(stageId, stageData, stageName)
    self.StageId = stageId
    self.StageName = stageName
    for key, value in pairs(default) do
        local tValue = stageData[1][key]
        self[key] = tValue and tValue or value
    end
  
    self.Head = XBodyCombinePart.New(stageData[1].ScrollPictures)
    self.Body = XBodyCombinePart.New(stageData[2].ScrollPictures)
    self.Legs = XBodyCombinePart.New(stageData[3].ScrollPictures)

    self.CorrectHead = XBodyCombinePart.New(stageData[1].ColPictures)
    self.CorrectBody = XBodyCombinePart.New(stageData[2].ColPictures)
    self.CorrectLegs = XBodyCombinePart.New(stageData[3].ColPictures)
end

function XBodyCombineStage:PlayNext(bodyPart)
    if not bodyPart then return end
    
    bodyPart:PlayNext()
end

function XBodyCombineStage:PlayLast(bodyPart)
    if not bodyPart then return end

    bodyPart:PlayLast()
end

function XBodyCombineStage:GetHead()
    return self.Head
end

function XBodyCombineStage:GetBody()
    return self.Body
end

function XBodyCombineStage:GetLegs()
    return self.Legs
end

--===========================================================================
 ---@desc 是否是正确答案
--===========================================================================
function XBodyCombineStage:IsCorrect()
    --头部对齐
    local isSameHead = self.Head:IsEqual(self.CorrectHead)
    if not isSameHead then return false end
    --身体对齐
    local isSameBody = self.Body:IsEqual(self.CorrectBody)
    if not isSameBody then return false end
    --脚对齐
    local isSameLegs = self.Legs:IsEqual(self.CorrectLegs)
    if not isSameLegs then return false end
    
    return true
end

--===========================================================================
 ---@desc 当前拼图数据
--===========================================================================
function XBodyCombineStage:GetCurData()
    local curData = { self.Head:GetCurData(), self.Body:GetCurData(), self.Legs:GetCurData() }
    return curData
end

---==============================
   ---@desc: 获取当前列的数据
   ---@param: 列数
---==============================
function XBodyCombineStage:GetColData(col)
    if not col or col <= 0 then 
        return {}
    end
    local headData = self.Head:GetCurData()
    local bodyData = self.Body:GetCurData()
    local LegsData = self.Legs:GetCurData()
    return headData[col], bodyData[col], LegsData[col]
end

---==============================
   ---@desc: 关卡ID 
---==============================
function XBodyCombineStage:GetStageId()
    return self.StageId
end

---==============================
   ---@desc: 前置关卡Id 
---==============================
function XBodyCombineStage:GetPreStageId()
    return self.PreStage
end

---==============================
   ---@desc: 关卡描述
---==============================
function XBodyCombineStage:GetDesc()
    return self.Desc
end

---==============================
   ---@desc: 问题描述，列表，长度最大为3
---==============================
function XBodyCombineStage:GetQuestionDesc()
    return self.QuestionDescs
end

---==============================
   ---@desc: 通关之后的图片（原来是未知）
   ---@return: 图片路径，可能为""
---==============================
function XBodyCombineStage:GetSuspectIcon()
    return self.SuspectIcon
end

---==============================
   ---@desc: 解锁消费
   ---@return: 消费金币数量
---==============================
function XBodyCombineStage:GetCost()
    return self.CostCount or 0
end

---==============================
   ---@desc: 通关描述
   ---@return: 描述文字
---==============================
function XBodyCombineStage:GetPassDesc()
    return self.PassDesc or ""
end

---==============================
   ---@desc:关卡开放封面图
   ---@return:封面图路径
---==============================
function XBodyCombineStage:GetOpenBanner()
    return self.OpenBanner
end

---==============================
   ---@desc:关卡完成封面图
   ---@return:封面图路径
---==============================
function XBodyCombineStage:GetFinishBanner()
    return self.FinishBanner
end

--==============================
 ---@desc:关卡名
--==============================
function XBodyCombineStage:GetStageName()
    return self.StageName or ""
end

function XBodyCombineStage:GetWinnerQIcon()
    return self.WinnerQIcon
end

return XBodyCombineStage
