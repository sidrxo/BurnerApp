"use client"

import * as React from "react"
import { ChevronDownIcon } from "lucide-react"

import { Button } from "@/components/ui/button"
import { Calendar } from "@/components/ui/calendar"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover"

interface DateTimeRangePickerProps {
  startValue?: string
  endValue?: string
  onStartChange?: (value: string) => void
  onEndChange?: (value: string) => void
}

export function DateTimeRangePicker({
  startValue = "",
  endValue = "",
  onStartChange,
  onEndChange,
}: DateTimeRangePickerProps) {
  const [startOpen, setStartOpen] = React.useState(false)
  const [endOpen, setEndOpen] = React.useState(false)

  // Parse the datetime strings to Date objects
  const startDate = startValue ? new Date(startValue) : undefined
  const endDate = endValue ? new Date(endValue) : undefined

  // Extract time from datetime string
  const getTimeFromDateTime = (dateTimeStr: string) => {
    if (!dateTimeStr) return ""
    const date = new Date(dateTimeStr)
    return date.toTimeString().slice(0, 8) // HH:MM:SS
  }

  const handleStartDateChange = (date: Date | undefined) => {
    if (date && onStartChange) {
      const time = getTimeFromDateTime(startValue) || "00:00:00"
      const [hours, minutes, seconds] = time.split(":")
      date.setHours(parseInt(hours), parseInt(minutes), parseInt(seconds))
      onStartChange(date.toISOString())
    }
    setStartOpen(false)
  }

  const handleEndDateChange = (date: Date | undefined) => {
    if (date && onEndChange) {
      const time = getTimeFromDateTime(endValue) || "00:00:00"
      const [hours, minutes, seconds] = time.split(":")
      date.setHours(parseInt(hours), parseInt(minutes), parseInt(seconds))
      onEndChange(date.toISOString())
    }
    setEndOpen(false)
  }

  const handleStartTimeChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (onStartChange) {
      const date = startDate || new Date()
      const [hours, minutes, seconds] = e.target.value.split(":")
      date.setHours(parseInt(hours), parseInt(minutes), parseInt(seconds || "0"))
      onStartChange(date.toISOString())
    }
  }

  const handleEndTimeChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (onEndChange) {
      const date = endDate || new Date()
      const [hours, minutes, seconds] = e.target.value.split(":")
      date.setHours(parseInt(hours), parseInt(minutes), parseInt(seconds || "0"))
      onEndChange(date.toISOString())
    }
  }

  return (
    <div className="flex flex-col gap-6">
      {/* Start Date & Time */}
      <div className="flex gap-4">
        <div className="flex flex-col gap-3">
          <Label htmlFor="start-date-picker" className="px-1">
            Start Date
          </Label>
          <Popover open={startOpen} onOpenChange={setStartOpen}>
            <PopoverTrigger asChild>
              <Button
                variant="outline"
                id="start-date-picker"
                className="w-40 justify-between font-normal"
              >
                {startDate ? startDate.toLocaleDateString() : "Select date"}
                <ChevronDownIcon />
              </Button>
            </PopoverTrigger>
            <PopoverContent className="w-auto overflow-hidden p-0" align="start">
              <Calendar
                mode="single"
                selected={startDate}
                captionLayout="dropdown"
                onSelect={handleStartDateChange}
                fromYear={2020}
                toYear={2035}
              />
            </PopoverContent>
          </Popover>
        </div>
        <div className="flex flex-col gap-3">
          <Label htmlFor="start-time-picker" className="px-1">
            Start Time
          </Label>
          <Input
            type="time"
            id="start-time-picker"
            step="1"
            value={getTimeFromDateTime(startValue)}
            onChange={handleStartTimeChange}
            className="bg-background appearance-none [&::-webkit-calendar-picker-indicator]:hidden [&::-webkit-calendar-picker-indicator]:appearance-none"
          />
        </div>
      </div>

      {/* End Date & Time */}
      <div className="flex gap-4">
        <div className="flex flex-col gap-3">
          <Label htmlFor="end-date-picker" className="px-1">
            End Date
          </Label>
          <Popover open={endOpen} onOpenChange={setEndOpen}>
            <PopoverTrigger asChild>
              <Button
                variant="outline"
                id="end-date-picker"
                className="w-40 justify-between font-normal"
              >
                {endDate ? endDate.toLocaleDateString() : "Select date"}
                <ChevronDownIcon />
              </Button>
            </PopoverTrigger>
            <PopoverContent className="w-auto overflow-hidden p-0" align="start">
              <Calendar
                mode="single"
                selected={endDate}
                captionLayout="dropdown"
                onSelect={handleEndDateChange}
                fromYear={2020}
                toYear={2035}
              />
            </PopoverContent>
          </Popover>
        </div>
        <div className="flex flex-col gap-3">
          <Label htmlFor="end-time-picker" className="px-1">
            End Time
          </Label>
          <Input
            type="time"
            id="end-time-picker"
            step="1"
            value={getTimeFromDateTime(endValue)}
            onChange={handleEndTimeChange}
            className="bg-background appearance-none [&::-webkit-calendar-picker-indicator]:hidden [&::-webkit-calendar-picker-indicator]:appearance-none"
          />
        </div>
      </div>
    </div>
  )
}