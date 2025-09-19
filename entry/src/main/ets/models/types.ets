export interface StudyRecord {
  date: string
  status: 'completed' | 'copied'
  note?: string
  timestamp?: number
}

export interface RouterParams {
  date: string
  status: string
  text?: string
}