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
  items?: NotebookItem[]
}

export interface NotebookItem {
  id: string
  name: string
  icon: string
}

export interface RouterParams {
  date: string
  status: string
  text?: string
  notebookId?: string
  notebook?: Notebook
}