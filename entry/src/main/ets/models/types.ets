export interface StudyRecord {
  date: string
  status: 'completed' | 'copied'
  note?: string
  timestamp?: number
  notebookId?: string
}

export interface Notebook {
  id: string
  title: string
  icon: string
  color?: string
}

export interface RouterParams {
  date: string
  status: string
  text?: string
  notebookId?: string
  notebook?: Notebook
}