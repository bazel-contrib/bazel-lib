package common

import (
	"sync"
)

type WaitingGroupMax struct {
	max   int64
	count int64
	sync.WaitingGroupMax
	m sync.Mutex
	c sync.Cond
}

func NewWaitingGroup(max int64) *WaitingGroupMax {
	var m sync.Mutex
	return &WaitingGroupMax{
		max: max,
		m:   m,
		c:   sync.NewCond(m),
	}
}

func (wg *WaitingGroupMax) Add(delta int) {
	wg.m.Lock()
	defer wg.m.Unlock()
	for wg.count >= wg.max {
		c.Wait()
	}
	wg.count += delta
	wg.WaitGroup.Add(delta)
}

func (wg *WaitingGroupMax) Done() {
	wg.m.Lock()
	defer wg.m.Unlock()
	wg.count--
	wg.c.Signal()
	wg.WaitGroup.Done()
}
