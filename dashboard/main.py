import tkinter as tk
from tkinter import ttk, messagebox
import mysql.connector
from mysql.connector import Error
from datetime import datetime
import matplotlib.pyplot as plt
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg
import configparser

class RailwayDashboard:
    def __init__(self, root):
        self.root = root
        self.root.title("Railway Management System Dashboard")
        self.root.geometry("1200x800")
        
        # Initialize attributes first
        self.status_var = tk.StringVar()
        self.status_var.set("Connecting to database...")
        
        # Create main container
        self.main_frame = ttk.Frame(root)
        self.main_frame.pack(fill=tk.BOTH, expand=True)
        
        # Status bar should be created before database connection
        self.status_bar = ttk.Label(root, textvariable=self.status_var, relief=tk.SUNKEN)
        self.status_bar.pack(fill=tk.X)
        
        # Now connect to database
        self.connection = None
        self.connect_to_db()
        
        # Rest of the initialization
        self.notebook = ttk.Notebook(self.main_frame)
        self.notebook.pack(fill=tk.BOTH, expand=True)
        
        self.create_dashboard_tab()
        self.create_passenger_tab()
        self.create_train_tab()
        self.create_ticket_tab()
        self.create_payment_tab()
        self.create_reports_tab()

    def connect_to_db(self):
        try:
            config = configparser.ConfigParser()
            config.read('db_config.ini')
            
            db_config = config['DATABASE']
            
            self.connection = mysql.connector.connect(
                host=db_config['host'].strip("'"),  # Remove any accidental quotes
                port=int(db_config['port']),  # Explicit conversion to int
                user=db_config['user'].strip("'"),
                password=db_config['password'].strip("'"),
                database=db_config['database'].strip("'")
            )

            if self.connection.is_connected():
                self.status_var.set("Connected to MySQL database")
        except Error as e:
            messagebox.showerror("Database Error", f"Error connecting to MySQL: {e}")
            self.root.destroy()
    
    def execute_query(self, query, params=None, fetch=True):
        try:
            cursor = self.connection.cursor(dictionary=True)
            cursor.execute(query, params or ())
            if fetch:
                result = cursor.fetchall()
                cursor.close()
                return result
            else:
                self.connection.commit()
                cursor.close()
                return True
        except Error as e:
            messagebox.showerror("Database Error", f"Error executing query: {e}")
            return None
    
    def create_dashboard_tab(self):
        self.dashboard_tab = ttk.Frame(self.notebook)
        self.notebook.add(self.dashboard_tab, text="Dashboard")
        
        # Dashboard widgets
        ttk.Label(self.dashboard_tab, text="Railway Management Dashboard", font=('Arial', 16)).pack(pady=10)
        
        # Stats frame
        stats_frame = ttk.LabelFrame(self.dashboard_tab, text="Quick Stats")
        stats_frame.pack(fill=tk.X, padx=10, pady=5)
        
        # Get stats from database
        total_passengers = self.execute_query("SELECT COUNT(*) as count FROM Passengers")[0]['count']
        total_trains = self.execute_query("SELECT COUNT(*) as count FROM Trains WHERE IsActive = TRUE")[0]['count']
        today_tickets = self.execute_query("SELECT COUNT(*) as count FROM Tickets WHERE DATE(BookingDateTime) = CURDATE()")[0]['count']
        revenue_today = self.execute_query("SELECT SUM(Amount) as total FROM Payments WHERE DATE(TransactionDateTime) = CURDATE() AND PaymentStatus = 'Completed'")[0]['total'] or 0
        
        # Display stats
        ttk.Label(stats_frame, text=f"Total Passengers: {total_passengers}").grid(row=0, column=0, padx=20, pady=5, sticky=tk.W)
        ttk.Label(stats_frame, text=f"Active Trains: {total_trains}").grid(row=0, column=1, padx=20, pady=5, sticky=tk.W)
        ttk.Label(stats_frame, text=f"Tickets Today: {today_tickets}").grid(row=1, column=0, padx=20, pady=5, sticky=tk.W)
        ttk.Label(stats_frame, text=f"Revenue Today: ₹{revenue_today:,.2f}").grid(row=1, column=1, padx=20, pady=5, sticky=tk.W)
        
        # Charts frame
        charts_frame = ttk.Frame(self.dashboard_tab)
        charts_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Ticket sales chart
        sales_frame = ttk.LabelFrame(charts_frame, text="Ticket Sales (Last 7 Days)")
        sales_frame.grid(row=0, column=0, padx=5, pady=5, sticky=tk.NSEW)
        
        # Get sales data
        sales_data = self.execute_query("""
            SELECT DATE(BookingDateTime) as date, COUNT(*) as count 
            FROM Tickets 
            WHERE BookingDateTime >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
            GROUP BY DATE(BookingDateTime)
            ORDER BY date
        """)
        
        dates = [row['date'].strftime('%m-%d') for row in sales_data]
        counts = [row['count'] for row in sales_data]
        
        fig1 = plt.Figure(figsize=(5, 3), dpi=100)
        ax1 = fig1.add_subplot(111)
        ax1.bar(dates, counts)
        ax1.set_title('Daily Ticket Sales')
        
        canvas1 = FigureCanvasTkAgg(fig1, master=sales_frame)
        canvas1.draw()
        canvas1.get_tk_widget().pack(fill=tk.BOTH, expand=True)
        
        # Revenue by class chart
        revenue_frame = ttk.LabelFrame(charts_frame, text="Revenue by Class (Today)")
        revenue_frame.grid(row=0, column=1, padx=5, pady=5, sticky=tk.NSEW)
        
        revenue_data = self.execute_query("""
            SELECT t.Class, SUM(p.Amount) as total 
            FROM Payments p
            JOIN Tickets t ON p.TicketID = t.TicketID
            WHERE DATE(p.TransactionDateTime) = CURDATE() AND p.PaymentStatus = 'Completed'
            GROUP BY t.Class
        """)
        
        classes = [row['Class'] for row in revenue_data]
        amounts = [row['total'] or 0 for row in revenue_data]
        
        fig2 = plt.Figure(figsize=(5, 3), dpi=100)
        ax2 = fig2.add_subplot(111)
        ax2.pie(amounts, labels=classes, autopct='%1.1f%%')
        ax2.set_title('Revenue by Class')
        
        canvas2 = FigureCanvasTkAgg(fig2, master=revenue_frame)
        canvas2.draw()
        canvas2.get_tk_widget().pack(fill=tk.BOTH, expand=True)
        
        charts_frame.columnconfigure(0, weight=1)
        charts_frame.columnconfigure(1, weight=1)
    
    def create_passenger_tab(self):
        self.passenger_tab = ttk.Frame(self.notebook)
        self.notebook.add(self.passenger_tab, text="Passengers")
        
        # Search frame
        search_frame = ttk.LabelFrame(self.passenger_tab, text="Search Passengers")
        search_frame.pack(fill=tk.X, padx=10, pady=5)
        
        ttk.Label(search_frame, text="Search:").grid(row=0, column=0, padx=5, pady=5)
        self.passenger_search_entry = ttk.Entry(search_frame, width=40)
        self.passenger_search_entry.grid(row=0, column=1, padx=5, pady=5)
        
        search_btn = ttk.Button(search_frame, text="Search", command=self.search_passengers)
        search_btn.grid(row=0, column=2, padx=5, pady=5)
        
        add_btn = ttk.Button(search_frame, text="Add New Passenger", command=self.add_passenger_dialog)
        add_btn.grid(row=0, column=3, padx=5, pady=5)
        
        # Passenger treeview
        columns = ("ID", "Name", "Age", "Gender", "Email", "Phone", "Disability")
        self.passenger_tree = ttk.Treeview(self.passenger_tab, columns=columns, show="headings")
        
        for col in columns:
            self.passenger_tree.heading(col, text=col)
            self.passenger_tree.column(col, width=100)
        
        self.passenger_tree.pack(fill=tk.BOTH, expand=True, padx=10, pady=5)
        
        # Load all passengers initially
        self.load_passengers()
        
        # Bind double click to edit
        self.passenger_tree.bind("<Double-1>", self.edit_passenger_dialog)
    
    def load_passengers(self, search_term=None):
        query = "SELECT PassengerID, CONCAT(FirstName, ' ', LastName) as Name, Age, Gender, Email, Phone, Disability FROM Passengers"
        params = None
        
        if search_term:
            query += " WHERE FirstName LIKE %s OR LastName LIKE %s OR Email LIKE %s OR Phone LIKE %s"
            params = (f"%{search_term}%", f"%{search_term}%", f"%{search_term}%", f"%{search_term}%")
        
        passengers = self.execute_query(query, params)
        
        # Clear treeview
        for row in self.passenger_tree.get_children():
            self.passenger_tree.delete(row)
            
        # Insert new data
        for passenger in passengers:
            disability = "Yes" if passenger['Disability'] else "No"
            self.passenger_tree.insert("", tk.END, values=(
                passenger['PassengerID'],
                passenger['Name'],
                passenger['Age'],
                passenger['Gender'],
                passenger['Email'],
                passenger['Phone'],
                disability
            ))
    
    def search_passengers(self):
        search_term = self.passenger_search_entry.get()
        self.load_passengers(search_term)
    
    def add_passenger_dialog(self):
        dialog = tk.Toplevel(self.root)
        dialog.title("Add New Passenger")
        dialog.geometry("400x400")
        
        ttk.Label(dialog, text="First Name:").grid(row=0, column=0, padx=5, pady=5, sticky=tk.E)
        first_name_entry = ttk.Entry(dialog)
        first_name_entry.grid(row=0, column=1, padx=5, pady=5)
        
        ttk.Label(dialog, text="Last Name:").grid(row=1, column=0, padx=5, pady=5, sticky=tk.E)
        last_name_entry = ttk.Entry(dialog)
        last_name_entry.grid(row=1, column=1, padx=5, pady=5)
        
        ttk.Label(dialog, text="Age:").grid(row=2, column=0, padx=5, pady=5, sticky=tk.E)
        age_entry = ttk.Entry(dialog)
        age_entry.grid(row=2, column=1, padx=5, pady=5)
        
        ttk.Label(dialog, text="Gender:").grid(row=3, column=0, padx=5, pady=5, sticky=tk.E)
        gender_combo = ttk.Combobox(dialog, values=["Male", "Female", "Other", "Prefer not to say"])
        gender_combo.grid(row=3, column=1, padx=5, pady=5)
        
        ttk.Label(dialog, text="Email:").grid(row=4, column=0, padx=5, pady=5, sticky=tk.E)
        email_entry = ttk.Entry(dialog)
        email_entry.grid(row=4, column=1, padx=5, pady=5)
        
        ttk.Label(dialog, text="Phone:").grid(row=5, column=0, padx=5, pady=5, sticky=tk.E)
        phone_entry = ttk.Entry(dialog)
        phone_entry.grid(row=5, column=1, padx=5, pady=5)
        
        disability_var = tk.BooleanVar()
        ttk.Checkbutton(dialog, text="Disability", variable=disability_var).grid(row=6, column=1, padx=5, pady=5, sticky=tk.W)
        
        def save_passenger():
            query = """
                INSERT INTO Passengers 
                (FirstName, LastName, Age, Gender, Email, Phone, Disability) 
                VALUES (%s, %s, %s, %s, %s, %s, %s)
            """
            params = (
                first_name_entry.get(),
                last_name_entry.get(),
                int(age_entry.get()),
                gender_combo.get(),
                email_entry.get(),
                phone_entry.get(),
                disability_var.get()
            )
            
            if self.execute_query(query, params, fetch=False):
                messagebox.showinfo("Success", "Passenger added successfully")
                self.load_passengers()
                dialog.destroy()
        
        save_btn = ttk.Button(dialog, text="Save", command=save_passenger)
        save_btn.grid(row=7, column=1, padx=5, pady=10)
    
    def edit_passenger_dialog(self, event):
        selected_item = self.passenger_tree.selection()
        if not selected_item:
            return
            
        passenger_id = self.passenger_tree.item(selected_item)['values'][0]
        
        # Get passenger details
        query = "SELECT * FROM Passengers WHERE PassengerID = %s"
        passenger = self.execute_query(query, (passenger_id,))[0]
        
        dialog = tk.Toplevel(self.root)
        dialog.title("Edit Passenger")
        dialog.geometry("400x400")
        
        ttk.Label(dialog, text="First Name:").grid(row=0, column=0, padx=5, pady=5, sticky=tk.E)
        first_name_entry = ttk.Entry(dialog)
        first_name_entry.insert(0, passenger['FirstName'])
        first_name_entry.grid(row=0, column=1, padx=5, pady=5)
        
        ttk.Label(dialog, text="Last Name:").grid(row=1, column=0, padx=5, pady=5, sticky=tk.E)
        last_name_entry = ttk.Entry(dialog)
        last_name_entry.insert(0, passenger['LastName'])
        last_name_entry.grid(row=1, column=1, padx=5, pady=5)
        
        ttk.Label(dialog, text="Age:").grid(row=2, column=0, padx=5, pady=5, sticky=tk.E)
        age_entry = ttk.Entry(dialog)
        age_entry.insert(0, passenger['Age'])
        age_entry.grid(row=2, column=1, padx=5, pady=5)
        
        ttk.Label(dialog, text="Gender:").grid(row=3, column=0, padx=5, pady=5, sticky=tk.E)
        gender_combo = ttk.Combobox(dialog, values=["Male", "Female", "Other", "Prefer not to say"])
        gender_combo.set(passenger['Gender'])
        gender_combo.grid(row=3, column=1, padx=5, pady=5)
        
        ttk.Label(dialog, text="Email:").grid(row=4, column=0, padx=5, pady=5, sticky=tk.E)
        email_entry = ttk.Entry(dialog)
        email_entry.insert(0, passenger['Email'])
        email_entry.grid(row=4, column=1, padx=5, pady=5)
        
        ttk.Label(dialog, text="Phone:").grid(row=5, column=0, padx=5, pady=5, sticky=tk.E)
        phone_entry = ttk.Entry(dialog)
        phone_entry.insert(0, passenger['Phone'])
        phone_entry.grid(row=5, column=1, padx=5, pady=5)
        
        disability_var = tk.BooleanVar(value=passenger['Disability'])
        ttk.Checkbutton(dialog, text="Disability", variable=disability_var).grid(row=6, column=1, padx=5, pady=5, sticky=tk.W)
        
        def update_passenger():
            query = """
                UPDATE Passengers 
                SET FirstName = %s, LastName = %s, Age = %s, Gender = %s, 
                    Email = %s, Phone = %s, Disability = %s
                WHERE PassengerID = %s
            """
            params = (
                first_name_entry.get(),
                last_name_entry.get(),
                int(age_entry.get()),
                gender_combo.get(),
                email_entry.get(),
                phone_entry.get(),
                disability_var.get(),
                passenger_id
            )
            
            if self.execute_query(query, params, fetch=False):
                messagebox.showinfo("Success", "Passenger updated successfully")
                self.load_passengers()
                dialog.destroy()
        
        save_btn = ttk.Button(dialog, text="Update", command=update_passenger)
        save_btn.grid(row=7, column=1, padx=5, pady=10)
        
        # Add delete button
        def delete_passenger():
            if messagebox.askyesno("Confirm", "Are you sure you want to delete this passenger?"):
                query = "DELETE FROM Passengers WHERE PassengerID = %s"
                if self.execute_query(query, (passenger_id,), fetch=False):
                    messagebox.showinfo("Success", "Passenger deleted successfully")
                    self.load_passengers()
                    dialog.destroy()
        
        delete_btn = ttk.Button(dialog, text="Delete", command=delete_passenger)
        delete_btn.grid(row=7, column=0, padx=5, pady=10)
    
    def create_train_tab(self):
        self.train_tab = ttk.Frame(self.notebook)
        self.notebook.add(self.train_tab, text="Trains")
        
        # Search frame
        search_frame = ttk.LabelFrame(self.train_tab, text="Search Trains")
        search_frame.pack(fill=tk.X, padx=10, pady=5)
        
        ttk.Label(search_frame, text="Search:").grid(row=0, column=0, padx=5, pady=5)
        self.train_search_entry = ttk.Entry(search_frame, width=40)
        self.train_search_entry.grid(row=0, column=1, padx=5, pady=5)
        
        search_btn = ttk.Button(search_frame, text="Search", command=self.search_trains)
        search_btn.grid(row=0, column=2, padx=5, pady=5)
        
        add_btn = ttk.Button(search_frame, text="Add New Train", command=self.add_train_dialog)
        add_btn.grid(row=0, column=3, padx=5, pady=5)
        
        # Train treeview
        columns = ("ID", "Number", "Name", "Type", "Origin", "Destination", "Distance", "Active")
        self.train_tree = ttk.Treeview(self.train_tab, columns=columns, show="headings")
        
        for col in columns:
            self.train_tree.heading(col, text=col)
            self.train_tree.column(col, width=100)
        
        self.train_tree.pack(fill=tk.BOTH, expand=True, padx=10, pady=5)
        
        # Load all trains initially
        self.load_trains()
        
        # Bind double click to edit
        self.train_tree.bind("<Double-1>", self.edit_train_dialog)
    
    def load_trains(self, search_term=None):
        query = """
            SELECT t.TrainID, t.TrainNumber, t.TrainName, t.TrainType, 
                   s1.StationName as Origin, s2.StationName as Destination,
                   t.TotalDistance, t.IsActive
            FROM Trains t
            JOIN Stations s1 ON t.OriginStationID = s1.StationID
            JOIN Stations s2 ON t.DestinationStationID = s2.StationID
        """
        params = None
        
        if search_term:
            query += " WHERE t.TrainNumber LIKE %s OR t.TrainName LIKE %s"
            params = (f"%{search_term}%", f"%{search_term}%")
        
        trains = self.execute_query(query, params)
        
        # Clear treeview
        for row in self.train_tree.get_children():
            self.train_tree.delete(row)
            
        # Insert new data
        for train in trains:
            active = "Yes" if train['IsActive'] else "No"
            self.train_tree.insert("", tk.END, values=(
                train['TrainID'],
                train['TrainNumber'],
                train['TrainName'],
                train['TrainType'],
                train['Origin'],
                train['Destination'],
                f"{train['TotalDistance']} km",
                active
            ))
    
    def search_trains(self):
        search_term = self.train_search_entry.get()
        self.load_trains(search_term)
    
    def add_train_dialog(self):
        dialog = tk.Toplevel(self.root)
        dialog.title("Add New Train")
        dialog.geometry("500x400")
        
        # Get stations for dropdowns
        stations = self.execute_query("SELECT StationID, StationName FROM Stations")
        station_names = [f"{s['StationID']} - {s['StationName']}" for s in stations]
        
        ttk.Label(dialog, text="Train Number:").grid(row=0, column=0, padx=5, pady=5, sticky=tk.E)
        train_num_entry = ttk.Entry(dialog)
        train_num_entry.grid(row=0, column=1, padx=5, pady=5)
        
        ttk.Label(dialog, text="Train Name:").grid(row=1, column=0, padx=5, pady=5, sticky=tk.E)
        train_name_entry = ttk.Entry(dialog)
        train_name_entry.grid(row=1, column=1, padx=5, pady=5)
        
        ttk.Label(dialog, text="Train Type:").grid(row=2, column=0, padx=5, pady=5, sticky=tk.E)
        train_type_combo = ttk.Combobox(dialog, values=[
            "Superfast", "Express", "Passenger", "Rajdhani", 
            "Shatabdi", "Duronto", "Vande Bharat", "Garib Rath", "Other"
        ])
        train_type_combo.grid(row=2, column=1, padx=5, pady=5)
        
        ttk.Label(dialog, text="Origin Station:").grid(row=3, column=0, padx=5, pady=5, sticky=tk.E)
        origin_combo = ttk.Combobox(dialog, values=station_names)
        origin_combo.grid(row=3, column=1, padx=5, pady=5)
        
        ttk.Label(dialog, text="Destination Station:").grid(row=4, column=0, padx=5, pady=5, sticky=tk.E)
        dest_combo = ttk.Combobox(dialog, values=station_names)
        dest_combo.grid(row=4, column=1, padx=5, pady=5)
        
        ttk.Label(dialog, text="Distance (km):").grid(row=5, column=0, padx=5, pady=5, sticky=tk.E)
        distance_entry = ttk.Entry(dialog)
        distance_entry.grid(row=5, column=1, padx=5, pady=5)
        
        active_var = tk.BooleanVar(value=True)
        ttk.Checkbutton(dialog, text="Active", variable=active_var).grid(row=6, column=1, padx=5, pady=5, sticky=tk.W)
        
        def save_train():
            origin_id = int(origin_combo.get().split(" - ")[0])
            dest_id = int(dest_combo.get().split(" - ")[0])
            
            query = """
                INSERT INTO Trains 
                (TrainNumber, TrainName, TrainType, OriginStationID, 
                 DestinationStationID, TotalDistance, IsActive) 
                VALUES (%s, %s, %s, %s, %s, %s, %s)
            """
            params = (
                train_num_entry.get(),
                train_name_entry.get(),
                train_type_combo.get(),
                origin_id,
                dest_id,
                int(distance_entry.get()),
                active_var.get()
            )
            
            if self.execute_query(query, params, fetch=False):
                messagebox.showinfo("Success", "Train added successfully")
                self.load_trains()
                dialog.destroy()
        
        save_btn = ttk.Button(dialog, text="Save", command=save_train)
        save_btn.grid(row=7, column=1, padx=5, pady=10)
    
    def edit_train_dialog(self, event):
        selected_item = self.train_tree.selection()
        if not selected_item:
            return
            
        train_id = self.train_tree.item(selected_item)['values'][0]
        
        # Get train details
        query = """
            SELECT t.*, s1.StationName as OriginName, s2.StationName as DestName
            FROM Trains t
            JOIN Stations s1 ON t.OriginStationID = s1.StationID
            JOIN Stations s2 ON t.DestinationStationID = s2.StationID
            WHERE t.TrainID = %s
        """
        train = self.execute_query(query, (train_id,))[0]
        
        dialog = tk.Toplevel(self.root)
        dialog.title("Edit Train")
        dialog.geometry("500x400")
        
        # Get stations for dropdowns
        stations = self.execute_query("SELECT StationID, StationName FROM Stations")
        station_names = [f"{s['StationID']} - {s['StationName']}" for s in stations]
        
        ttk.Label(dialog, text="Train Number:").grid(row=0, column=0, padx=5, pady=5, sticky=tk.E)
        train_num_entry = ttk.Entry(dialog)
        train_num_entry.insert(0, train['TrainNumber'])
        train_num_entry.grid(row=0, column=1, padx=5, pady=5)
        
        ttk.Label(dialog, text="Train Name:").grid(row=1, column=0, padx=5, pady=5, sticky=tk.E)
        train_name_entry = ttk.Entry(dialog)
        train_name_entry.insert(0, train['TrainName'])
        train_name_entry.grid(row=1, column=1, padx=5, pady=5)
        
        ttk.Label(dialog, text="Train Type:").grid(row=2, column=0, padx=5, pady=5, sticky=tk.E)
        train_type_combo = ttk.Combobox(dialog, values=[
            "Superfast", "Express", "Passenger", "Rajdhani", 
            "Shatabdi", "Duronto", "Vande Bharat", "Garib Rath", "Other"
        ])
        train_type_combo.set(train['TrainType'])
        train_type_combo.grid(row=2, column=1, padx=5, pady=5)
        
        ttk.Label(dialog, text="Origin Station:").grid(row=3, column=0, padx=5, pady=5, sticky=tk.E)
        origin_combo = ttk.Combobox(dialog, values=station_names)
        origin_combo.set(f"{train['OriginStationID']} - {train['OriginName']}")
        origin_combo.grid(row=3, column=1, padx=5, pady=5)
        
        ttk.Label(dialog, text="Destination Station:").grid(row=4, column=0, padx=5, pady=5, sticky=tk.E)
        dest_combo = ttk.Combobox(dialog, values=station_names)
        dest_combo.set(f"{train['DestinationStationID']} - {train['DestName']}")
        dest_combo.grid(row=4, column=1, padx=5, pady=5)
        
        ttk.Label(dialog, text="Distance (km):").grid(row=5, column=0, padx=5, pady=5, sticky=tk.E)
        distance_entry = ttk.Entry(dialog)
        distance_entry.insert(0, train['TotalDistance'])
        distance_entry.grid(row=5, column=1, padx=5, pady=5)
        
        active_var = tk.BooleanVar(value=train['IsActive'])
        ttk.Checkbutton(dialog, text="Active", variable=active_var).grid(row=6, column=1, padx=5, pady=5, sticky=tk.W)
        
        def update_train():
            origin_id = int(origin_combo.get().split(" - ")[0])
            dest_id = int(dest_combo.get().split(" - ")[0])
            
            query = """
                UPDATE Trains 
                SET TrainNumber = %s, TrainName = %s, TrainType = %s, 
                    OriginStationID = %s, DestinationStationID = %s, 
                    TotalDistance = %s, IsActive = %s
                WHERE TrainID = %s
            """
            params = (
                train_num_entry.get(),
                train_name_entry.get(),
                train_type_combo.get(),
                origin_id,
                dest_id,
                int(distance_entry.get()),
                active_var.get(),
                train_id
            )
            
            if self.execute_query(query, params, fetch=False):
                messagebox.showinfo("Success", "Train updated successfully")
                self.load_trains()
                dialog.destroy()
        
        save_btn = ttk.Button(dialog, text="Update", command=update_train)
        save_btn.grid(row=7, column=1, padx=5, pady=10)
        
        # Add delete button
        def delete_train():
            if messagebox.askyesno("Confirm", "Are you sure you want to delete this train?"):
                query = "DELETE FROM Trains WHERE TrainID = %s"
                if self.execute_query(query, (train_id,), fetch=False):
                    messagebox.showinfo("Success", "Train deleted successfully")
                    self.load_trains()
                    dialog.destroy()
        
        delete_btn = ttk.Button(dialog, text="Delete", command=delete_train)
        delete_btn.grid(row=7, column=0, padx=5, pady=10)
    
    def create_ticket_tab(self):
        self.ticket_tab = ttk.Frame(self.notebook)
        self.notebook.add(self.ticket_tab, text="Tickets")
        
        # Search frame
        search_frame = ttk.LabelFrame(self.ticket_tab, text="Search Tickets")
        search_frame.pack(fill=tk.X, padx=10, pady=5)
        
        ttk.Label(search_frame, text="PNR Number:").grid(row=0, column=0, padx=5, pady=5)
        self.pnr_search_entry = ttk.Entry(search_frame, width=20)
        self.pnr_search_entry.grid(row=0, column=1, padx=5, pady=5)
        
        search_btn = ttk.Button(search_frame, text="Search by PNR", command=self.search_tickets_by_pnr)
        search_btn.grid(row=0, column=2, padx=5, pady=5)
        
        ttk.Label(search_frame, text="Passenger Name:").grid(row=1, column=0, padx=5, pady=5)
        self.passenger_search_entry = ttk.Entry(search_frame, width=20)
        self.passenger_search_entry.grid(row=1, column=1, padx=5, pady=5)
        
        search_btn2 = ttk.Button(search_frame, text="Search by Passenger", command=self.search_tickets_by_passenger)
        search_btn2.grid(row=1, column=2, padx=5, pady=5)
        
        ttk.Label(search_frame, text="Date Range:").grid(row=2, column=0, padx=5, pady=5)
        self.from_date_entry = ttk.Entry(search_frame, width=10)
        self.from_date_entry.grid(row=2, column=1, padx=5, pady=5)
        
        ttk.Label(search_frame, text="to").grid(row=2, column=2, padx=5, pady=5)
        self.to_date_entry = ttk.Entry(search_frame, width=10)
        self.to_date_entry.grid(row=2, column=3, padx=5, pady=5)
        
        search_btn3 = ttk.Button(search_frame, text="Search by Date", command=self.search_tickets_by_date)
        search_btn3.grid(row=2, column=4, padx=5, pady=5)
        
        book_btn = ttk.Button(search_frame, text="Book New Ticket", command=self.book_ticket_dialog)
        book_btn.grid(row=0, column=5, padx=5, pady=5, rowspan=3)
        
        # Ticket treeview
        columns = ("PNR", "Passenger", "Train", "Class", "Journey Date", "Status", "Fare")
        self.ticket_tree = ttk.Treeview(self.ticket_tab, columns=columns, show="headings")
        
        for col in columns:
            self.ticket_tree.heading(col, text=col)
            self.ticket_tree.column(col, width=100)
        
        self.ticket_tree.pack(fill=tk.BOTH, expand=True, padx=10, pady=5)
        
        # Load all tickets initially
        self.load_tickets()
        
        # Bind double click to view details
        self.ticket_tree.bind("<Double-1>", self.view_ticket_details)
    
    def load_tickets(self, pnr=None, passenger_name=None, from_date=None, to_date=None):
        query = """
            SELECT t.PNRNo, CONCAT(p.FirstName, ' ', p.LastName) as PassengerName, 
                   tr.TrainName, t.Class, t.JourneyDate, t.Status, t.Fare
            FROM Tickets t
            JOIN Passengers p ON t.PassengerID = p.PassengerID
            JOIN Trains tr ON t.TrainID = tr.TrainID
        """
        params = []
        conditions = []
        
        if pnr:
            conditions.append("t.PNRNo LIKE %s")
            params.append(f"%{pnr}%")
        
        if passenger_name:
            conditions.append("(p.FirstName LIKE %s OR p.LastName LIKE %s)")
            params.extend([f"%{passenger_name}%", f"%{passenger_name}%"])
        
        if from_date and to_date:
            conditions.append("t.JourneyDate BETWEEN %s AND %s")
            params.extend([from_date, to_date])
        
        if conditions:
            query += " WHERE " + " AND ".join(conditions)
        
        query += " ORDER BY t.JourneyDate DESC"
        
        tickets = self.execute_query(query, params or None)
        
        # Clear treeview
        for row in self.ticket_tree.get_children():
            self.ticket_tree.delete(row)
            
        # Insert new data
        for ticket in tickets:
            self.ticket_tree.insert("", tk.END, values=(
                ticket['PNRNo'],
                ticket['PassengerName'],
                ticket['TrainName'],
                ticket['Class'],
                ticket['JourneyDate'].strftime('%Y-%m-%d'),
                ticket['Status'],
                f"₹{ticket['Fare']:,.2f}"
            ))
    
    def search_tickets_by_pnr(self):
        pnr = self.pnr_search_entry.get()
        self.load_tickets(pnr=pnr)
    
    def search_tickets_by_passenger(self):
        passenger_name = self.passenger_search_entry.get()
        self.load_tickets(passenger_name=passenger_name)
    
    def search_tickets_by_date(self):
        from_date = self.from_date_entry.get()
        to_date = self.to_date_entry.get()
        self.load_tickets(from_date=from_date, to_date=to_date)
    
    def book_ticket_dialog(self):
        dialog = tk.Toplevel(self.root)
        dialog.title("Book New Ticket")
        dialog.geometry("600x500")

            # Get passengers for dropdown
        passengers = self.execute_query("SELECT PassengerID, CONCAT(FirstName, ' ', LastName) as Name FROM Passengers")
        passenger_options = [f"{p['PassengerID']} - {p['Name']}" for p in passengers]
        
        # Get active trains
        trains = self.execute_query("SELECT TrainID, TrainName FROM Trains WHERE IsActive = TRUE")
        train_options = [f"{t['TrainID']} - {t['TrainName']}" for t in trains]
        
        # Get classes
        classes = self.execute_query("SELECT ClassName FROM Classes")
        class_options = [c['ClassName'] for c in classes]
        
        ttk.Label(dialog, text="Passenger:").grid(row=0, column=0, padx=5, pady=5, sticky=tk.E)
        passenger_combo = ttk.Combobox(dialog, values=passenger_options)
        passenger_combo.grid(row=0, column=1, padx=5, pady=5)
        
        ttk.Label(dialog, text="Train:").grid(row=1, column=0, padx=5, pady=5, sticky=tk.E)
        train_combo = ttk.Combobox(dialog, values=train_options)
        train_combo.grid(row=1, column=1, padx=5, pady=5)
        
        ttk.Label(dialog, text="Class:").grid(row=2, column=0, padx=5, pady=5, sticky=tk.E)
        class_combo = ttk.Combobox(dialog, values=class_options)
        class_combo.grid(row=2, column=1, padx=5, pady=5)
        
        ttk.Label(dialog, text="Journey Date:").grid(row=3, column=0, padx=5, pady=5, sticky=tk.E)
        journey_date_entry = ttk.Entry(dialog)
        journey_date_entry.grid(row=3, column=1, padx=5, pady=5)
        
        ttk.Label(dialog, text="Payment Method:").grid(row=4, column=0, padx=5, pady=5, sticky=tk.E)
        payment_combo = ttk.Combobox(dialog, values=[
            "Credit Card", "Debit Card", "Net Banking", "UPI", "Wallet", "Cash"
        ])
        payment_combo.grid(row=4, column=1, padx=5, pady=5)
        
        # Display fare
        fare_label = ttk.Label(dialog, text="Fare: ₹0.00")
        fare_label.grid(row=5, column=0, columnspan=2, padx=5, pady=5)
        
        def calculate_fare():
            try:
                passenger_id = int(passenger_combo.get().split(" - ")[0])
                train_id = int(train_combo.get().split(" - ")[0])
                class_name = class_combo.get()
                
                fare = self.execute_query(
                    "SELECT CalculateTicketFare(%s, %s, %s) as fare",
                    (train_id, class_name, passenger_id)
                )[0]['fare']
                
                fare_label.config(text=f"Fare: ₹{fare:,.2f}")
            except:
                fare_label.config(text="Fare: Please select all fields")
        
        # Bind combobox changes to calculate fare
        passenger_combo.bind("<<ComboboxSelected>>", lambda e: calculate_fare())
        train_combo.bind("<<ComboboxSelected>>", lambda e: calculate_fare())
        class_combo.bind("<<ComboboxSelected>>", lambda e: calculate_fare())
    
        def book_ticket():
            try:
                passenger_id = int(passenger_combo.get().split(" - ")[0])
                train_id = int(train_combo.get().split(" - ")[0])
                class_name = class_combo.get()
                journey_date = journey_date_entry.get()
                payment_mode = payment_combo.get()
                
                if not all([passenger_id, train_id, class_name, journey_date, payment_mode]):
                    messagebox.showerror("Error", "Please fill all fields")
                    return
                
                # Call the stored procedure
                query = "CALL BookTicket(%s, %s, %s, %s, %s)"
                params = (passenger_id, train_id, class_name, journey_date, payment_mode)
                
                if self.execute_query(query, params, fetch=False):
                    messagebox.showinfo("Success", "Ticket booked successfully!")
                    self.load_tickets()
                    dialog.destroy()
            except Exception as e:
                messagebox.showerror("Error", f"Failed to book ticket: {str(e)}")
    
        book_btn = ttk.Button(dialog, text="Book Ticket", command=book_ticket)
        book_btn.grid(row=6, column=0, columnspan=2, padx=5, pady=10)

    def view_ticket_details(self, event):
        selected_item = self.ticket_tree.selection()
        if not selected_item:
            return
            
        pnr = self.ticket_tree.item(selected_item)['values'][0]
        
        # Get ticket details
        query = """
            SELECT t.*, p.FirstName, p.LastName, p.Age, p.Gender, 
                tr.TrainName, tr.TrainNumber,
                s1.StationName as SourceStation, 
                s2.StationName as DestStation
            FROM Tickets t
            JOIN Passengers p ON t.PassengerID = p.PassengerID
            JOIN Trains tr ON t.TrainID = tr.TrainID
            JOIN Stations s1 ON t.SourceStationID = s1.StationID
            JOIN Stations s2 ON t.DestinationStationID = s2.StationID
            WHERE t.PNRNo = %s
        """
        ticket = self.execute_query(query, (pnr,))[0]
        
        dialog = tk.Toplevel(self.root)
        dialog.title(f"Ticket Details - PNR: {pnr}")
        dialog.geometry("600x500")
        
        # Create notebook for ticket details
        notebook = ttk.Notebook(dialog)
        notebook.pack(fill=tk.BOTH, expand=True)
        
        # Ticket info tab
        info_tab = ttk.Frame(notebook)
        notebook.add(info_tab, text="Ticket Information")
        
        # Passenger info
        ttk.Label(info_tab, text="Passenger Information", font=('Arial', 12, 'bold')).grid(row=0, column=0, columnspan=2, pady=5, sticky=tk.W)
        
        ttk.Label(info_tab, text="Name:").grid(row=1, column=0, padx=5, pady=2, sticky=tk.E)
        ttk.Label(info_tab, text=f"{ticket['FirstName']} {ticket['LastName']}").grid(row=1, column=1, padx=5, pady=2, sticky=tk.W)
        
        ttk.Label(info_tab, text="Age:").grid(row=2, column=0, padx=5, pady=2, sticky=tk.E)
        ttk.Label(info_tab, text=ticket['Age']).grid(row=2, column=1, padx=5, pady=2, sticky=tk.W)
        
        ttk.Label(info_tab, text="Gender:").grid(row=3, column=0, padx=5, pady=2, sticky=tk.E)
        ttk.Label(info_tab, text=ticket['Gender']).grid(row=3, column=1, padx=5, pady=2, sticky=tk.W)
        
        # Ticket info
        ttk.Label(info_tab, text="Journey Information", font=('Arial', 12, 'bold')).grid(row=4, column=0, columnspan=2, pady=5, sticky=tk.W)
        
        ttk.Label(info_tab, text="Train:").grid(row=5, column=0, padx=5, pady=2, sticky=tk.E)
        ttk.Label(info_tab, text=f"{ticket['TrainNumber']} - {ticket['TrainName']}").grid(row=5, column=1, padx=5, pady=2, sticky=tk.W)
        
        ttk.Label(info_tab, text="Class:").grid(row=6, column=0, padx=5, pady=2, sticky=tk.E)
        ttk.Label(info_tab, text=ticket['Class']).grid(row=6, column=1, padx=5, pady=2, sticky=tk.W)
        
        ttk.Label(info_tab, text="Journey Date:").grid(row=7, column=0, padx=5, pady=2, sticky=tk.E)
        ttk.Label(info_tab, text=ticket['JourneyDate'].strftime('%Y-%m-%d')).grid(row=7, column=1, padx=5, pady=2, sticky=tk.W)
        
        ttk.Label(info_tab, text="From:").grid(row=8, column=0, padx=5, pady=2, sticky=tk.E)
        ttk.Label(info_tab, text=ticket['SourceStation']).grid(row=8, column=1, padx=5, pady=2, sticky=tk.W)
        
        ttk.Label(info_tab, text="To:").grid(row=9, column=0, padx=5, pady=2, sticky=tk.E)
        ttk.Label(info_tab, text=ticket['DestStation']).grid(row=9, column=1, padx=5, pady=2, sticky=tk.W)
        
        ttk.Label(info_tab, text="Status:").grid(row=10, column=0, padx=5, pady=2, sticky=tk.E)
        ttk.Label(info_tab, text=ticket['Status']).grid(row=10, column=1, padx=5, pady=2, sticky=tk.W)
        
        ttk.Label(info_tab, text="Seat/Coach:").grid(row=11, column=0, padx=5, pady=2, sticky=tk.E)
        seat_text = f"{ticket['SeatNo']}/{ticket['CoachNo']}" if ticket['SeatNo'] else "Waiting List"
        ttk.Label(info_tab, text=seat_text).grid(row=11, column=1, padx=5, pady=2, sticky=tk.W)
        
        ttk.Label(info_tab, text="Fare:").grid(row=12, column=0, padx=5, pady=2, sticky=tk.E)
        ttk.Label(info_tab, text=f"₹{ticket['Fare']:,.2f}").grid(row=12, column=1, padx=5, pady=2, sticky=tk.W)
        
        ttk.Label(info_tab, text="Concession:").grid(row=13, column=0, padx=5, pady=2, sticky=tk.E)
        ttk.Label(info_tab, text=f"₹{ticket['ConcessionAmount']:,.2f}").grid(row=13, column=1, padx=5, pady=2, sticky=tk.W)
        
        # Payment info tab
        payment_tab = ttk.Frame(notebook)
        notebook.add(payment_tab, text="Payment Information")
        
        # Get payment details
        payment_query = "SELECT * FROM Payments WHERE TicketID = %s"
        payment = self.execute_query(payment_query, (ticket['TicketID'],))[0]
        
        ttk.Label(payment_tab, text="Payment Details", font=('Arial', 12, 'bold')).grid(row=0, column=0, columnspan=2, pady=5, sticky=tk.W)
        
        ttk.Label(payment_tab, text="Amount:").grid(row=1, column=0, padx=5, pady=2, sticky=tk.E)
        ttk.Label(payment_tab, text=f"₹{payment['Amount']:,.2f}").grid(row=1, column=1, padx=5, pady=2, sticky=tk.W)
        
        ttk.Label(payment_tab, text="Payment Mode:").grid(row=2, column=0, padx=5, pady=2, sticky=tk.E)
        ttk.Label(payment_tab, text=payment['PaymentMode']).grid(row=2, column=1, padx=5, pady=2, sticky=tk.W)
        
        ttk.Label(payment_tab, text="Status:").grid(row=3, column=0, padx=5, pady=2, sticky=tk.E)
        ttk.Label(payment_tab, text=payment['PaymentStatus']).grid(row=3, column=1, padx=5, pady=2, sticky=tk.W)
        
        ttk.Label(payment_tab, text="Transaction ID:").grid(row=4, column=0, padx=5, pady=2, sticky=tk.E)
        ttk.Label(payment_tab, text=payment['TransactionID']).grid(row=4, column=1, padx=5, pady=2, sticky=tk.W)
        
        ttk.Label(payment_tab, text="Date/Time:").grid(row=5, column=0, padx=5, pady=2, sticky=tk.E)
        ttk.Label(payment_tab, text=payment['TransactionDateTime'].strftime('%Y-%m-%d %H:%M:%S')).grid(row=5, column=1, padx=5, pady=2, sticky=tk.W)
        
        # Add cancel button if ticket is confirmed
        if ticket['Status'] == 'Confirmed':
            def cancel_ticket():
                if messagebox.askyesno("Confirm Cancellation", "Are you sure you want to cancel this ticket?"):
                    # Calculate refund amount (80% of fare)
                    refund_amount = ticket['Fare'] * 0.8
                    
                    # Update ticket status
                    update_query = "UPDATE Tickets SET Status = 'Cancelled' WHERE TicketID = %s"
                    self.execute_query(update_query, (ticket['TicketID'],), fetch=False)
                    
                    # Record cancellation
                    cancel_query = """
                        INSERT INTO Cancellations 
                        (TicketID, CancellationDateTime, RefundAmount, RefundStatus) 
                        VALUES (%s, NOW(), %s, 'Pending')
                    """
                    self.execute_query(cancel_query, (ticket['TicketID'], refund_amount), fetch=False)
                    
                    # Update payment status
                    payment_update = "UPDATE Payments SET PaymentStatus = 'Refunded' WHERE TicketID = %s"
                    self.execute_query(payment_update, (ticket['TicketID'],), fetch=False)
                    
                    messagebox.showinfo("Success", f"Ticket cancelled. Refund amount: ₹{refund_amount:,.2f}")
                    self.load_tickets()
                    dialog.destroy()
            
            cancel_btn = ttk.Button(info_tab, text="Cancel Ticket", command=cancel_ticket)
            cancel_btn.grid(row=14, column=0, columnspan=2, pady=10)

    def create_payment_tab(self):
        self.payment_tab = ttk.Frame(self.notebook)
        self.notebook.add(self.payment_tab, text="Payments")
        
        # Search frame
        search_frame = ttk.LabelFrame(self.payment_tab, text="Search Payments")
        search_frame.pack(fill=tk.X, padx=10, pady=5)
        
        ttk.Label(search_frame, text="Date Range:").grid(row=0, column=0, padx=5, pady=5)
        self.payment_from_date = ttk.Entry(search_frame, width=10)
        self.payment_from_date.grid(row=0, column=1, padx=5, pady=5)
        
        ttk.Label(search_frame, text="to").grid(row=0, column=2, padx=5, pady=5)
        self.payment_to_date = ttk.Entry(search_frame, width=10)
        self.payment_to_date.grid(row=0, column=3, padx=5, pady=5)
        
        ttk.Label(search_frame, text="Status:").grid(row=0, column=4, padx=5, pady=5)
        self.payment_status_combo = ttk.Combobox(search_frame, values=["All", "Completed", "Pending", "Failed", "Refunded"])
        self.payment_status_combo.set("All")
        self.payment_status_combo.grid(row=0, column=5, padx=5, pady=5)
        
        search_btn = ttk.Button(search_frame, text="Search", command=self.search_payments)
        search_btn.grid(row=0, column=6, padx=5, pady=5)
        
        # Payment treeview
        columns = ("ID", "Ticket PNR", "Amount", "Mode", "Status", "Date/Time", "Transaction ID")
        self.payment_tree = ttk.Treeview(self.payment_tab, columns=columns, show="headings")
        
        for col in columns:
            self.payment_tree.heading(col, text=col)
            self.payment_tree.column(col, width=100)
        
        self.payment_tree.pack(fill=tk.BOTH, expand=True, padx=10, pady=5)
        
        # Load all payments initially
        self.load_payments()
        
        # Bind double click to view details
        self.payment_tree.bind("<Double-1>", self.view_payment_details)

    def load_payments(self, from_date=None, to_date=None, status="All"):
        query = """
            SELECT p.PaymentID, t.PNRNo, p.Amount, p.PaymentMode, 
                p.PaymentStatus, p.TransactionDateTime, p.TransactionID
            FROM Payments p
            JOIN Tickets t ON p.TicketID = t.TicketID
        """
        params = []
        conditions = []
        
        if from_date and to_date:
            conditions.append("DATE(p.TransactionDateTime) BETWEEN %s AND %s")
            params.extend([from_date, to_date])
        
        if status != "All":
            conditions.append("p.PaymentStatus = %s")
            params.append(status)
        
        if conditions:
            query += " WHERE " + " AND ".join(conditions)
        
        query += " ORDER BY p.TransactionDateTime DESC"
        
        payments = self.execute_query(query, params or None)
        
        # Clear treeview
        for row in self.payment_tree.get_children():
            self.payment_tree.delete(row)
            
        # Insert new data
        for payment in payments:
            self.payment_tree.insert("", tk.END, values=(
                payment['PaymentID'],
                payment['PNRNo'],
                f"₹{payment['Amount']:,.2f}",
                payment['PaymentMode'],
                payment['PaymentStatus'],
                payment['TransactionDateTime'].strftime('%Y-%m-%d %H:%M'),
                payment['TransactionID']
            ))

    def search_payments(self):
        from_date = self.payment_from_date.get()
        to_date = self.payment_to_date.get()
        status = self.payment_status_combo.get()
        
        self.load_payments(from_date, to_date, status)

    def view_payment_details(self, event):
        selected_item = self.payment_tree.selection()
        if not selected_item:
            return
            
        payment_id = self.payment_tree.item(selected_item)['values'][0]
        
        # Get payment details
        query = """
            SELECT p.*, t.PNRNo, CONCAT(ps.FirstName, ' ', ps.LastName) as PassengerName,
                tr.TrainName, t.Class, t.JourneyDate
            FROM Payments p
            JOIN Tickets t ON p.TicketID = t.TicketID
            JOIN Passengers ps ON t.PassengerID = ps.PassengerID
            JOIN Trains tr ON t.TrainID = tr.TrainID
            WHERE p.PaymentID = %s
        """
        payment = self.execute_query(query, (payment_id,))[0]
        
        dialog = tk.Toplevel(self.root)
        dialog.title(f"Payment Details - ID: {payment_id}")
        dialog.geometry("500x400")
        
        ttk.Label(dialog, text="Payment Details", font=('Arial', 14, 'bold')).pack(pady=10)
        
        details_frame = ttk.Frame(dialog)
        details_frame.pack(fill=tk.BOTH, padx=10, pady=5, expand=True)
        
        # Payment info
        ttk.Label(details_frame, text="Amount:").grid(row=0, column=0, padx=5, pady=5, sticky=tk.E)
        ttk.Label(details_frame, text=f"₹{payment['Amount']:,.2f}").grid(row=0, column=1, padx=5, pady=5, sticky=tk.W)
        
        ttk.Label(details_frame, text="Mode:").grid(row=1, column=0, padx=5, pady=5, sticky=tk.E)
        ttk.Label(details_frame, text=payment['PaymentMode']).grid(row=1, column=1, padx=5, pady=5, sticky=tk.W)
        
        ttk.Label(details_frame, text="Status:").grid(row=2, column=0, padx=5, pady=5, sticky=tk.E)
        ttk.Label(details_frame, text=payment['PaymentStatus']).grid(row=2, column=1, padx=5, pady=5, sticky=tk.W)
        
        ttk.Label(details_frame, text="Transaction ID:").grid(row=3, column=0, padx=5, pady=5, sticky=tk.E)
        ttk.Label(details_frame, text=payment['TransactionID']).grid(row=3, column=1, padx=5, pady=5, sticky=tk.W)
        
        ttk.Label(details_frame, text="Date/Time:").grid(row=4, column=0, padx=5, pady=5, sticky=tk.E)
        ttk.Label(details_frame, text=payment['TransactionDateTime'].strftime('%Y-%m-%d %H:%M:%S')).grid(row=4, column=1, padx=5, pady=5, sticky=tk.W)
        
        # Ticket info
        ttk.Label(details_frame, text="Ticket Information", font=('Arial', 12, 'bold')).grid(row=5, column=0, columnspan=2, pady=10, sticky=tk.W)
        
        ttk.Label(details_frame, text="PNR:").grid(row=6, column=0, padx=5, pady=2, sticky=tk.E)
        ttk.Label(details_frame, text=payment['PNRNo']).grid(row=6, column=1, padx=5, pady=2, sticky=tk.W)
        
        ttk.Label(details_frame, text="Passenger:").grid(row=7, column=0, padx=5, pady=2, sticky=tk.E)
        ttk.Label(details_frame, text=payment['PassengerName']).grid(row=7, column=1, padx=5, pady=2, sticky=tk.W)
        
        ttk.Label(details_frame, text="Train:").grid(row=8, column=0, padx=5, pady=2, sticky=tk.E)
        ttk.Label(details_frame, text=payment['TrainName']).grid(row=8, column=1, padx=5, pady=2, sticky=tk.W)
        
        ttk.Label(details_frame, text="Class:").grid(row=9, column=0, padx=5, pady=2, sticky=tk.E)
        ttk.Label(details_frame, text=payment['Class']).grid(row=9, column=1, padx=5, pady=2, sticky=tk.W)
        
        ttk.Label(details_frame, text="Journey Date:").grid(row=10, column=0, padx=5, pady=2, sticky=tk.E)
        ttk.Label(details_frame, text=payment['JourneyDate'].strftime('%Y-%m-%d')).grid(row=10, column=1, padx=5, pady=2, sticky=tk.W)

    def create_reports_tab(self):
        self.reports_tab = ttk.Frame(self.notebook)
        self.notebook.add(self.reports_tab, text="Reports")
        
        # Report selection
        report_frame = ttk.LabelFrame(self.reports_tab, text="Generate Report")
        report_frame.pack(fill=tk.X, padx=10, pady=5)
        
        ttk.Label(report_frame, text="Report Type:").grid(row=0, column=0, padx=5, pady=5)
        self.report_type = ttk.Combobox(report_frame, values=[
            "Daily Ticket Sales",
            "Revenue by Train",
            "Revenue by Class",
            "Cancellation Analysis",
            "Passenger Demographics"
        ])
        self.report_type.grid(row=0, column=1, padx=5, pady=5)
        
        ttk.Label(report_frame, text="Date Range:").grid(row=1, column=0, padx=5, pady=5)
        self.report_from_date = ttk.Entry(report_frame, width=10)
        self.report_from_date.grid(row=1, column=1, padx=5, pady=5)
        
        ttk.Label(report_frame, text="to").grid(row=1, column=2, padx=5, pady=5)
        self.report_to_date = ttk.Entry(report_frame, width=10)
        self.report_to_date.grid(row=1, column=3, padx=5, pady=5)
        
        generate_btn = ttk.Button(report_frame, text="Generate Report", command=self.generate_report)
        generate_btn.grid(row=1, column=4, padx=5, pady=5)
        
        # Report display area
        self.report_text = tk.Text(self.reports_tab, wrap=tk.WORD)
        self.report_text.pack(fill=tk.BOTH, expand=True, padx=10, pady=5)
        
        # Chart area
        self.chart_frame = ttk.Frame(self.reports_tab)
        self.chart_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=5)

    def generate_report(self):
        report_type = self.report_type.get()
        from_date = self.report_from_date.get()
        to_date = self.report_to_date.get()
        
        if not report_type:
            messagebox.showerror("Error", "Please select a report type")
            return
        
        # Clear previous content
        self.report_text.delete(1.0, tk.END)
        
        # Clear previous chart
        for widget in self.chart_frame.winfo_children():
            widget.destroy()
        
        try:
            if report_type == "Daily Ticket Sales":
                self.generate_daily_sales_report(from_date, to_date)
            elif report_type == "Revenue by Train":
                self.generate_revenue_by_train_report(from_date, to_date)
            elif report_type == "Revenue by Class":
                self.generate_revenue_by_class_report(from_date, to_date)
            elif report_type == "Cancellation Analysis":
                self.generate_cancellation_report(from_date, to_date)
            elif report_type == "Passenger Demographics":
                self.generate_demographics_report()
        except Exception as e:
            messagebox.showerror("Error", f"Failed to generate report: {str(e)}")

    def generate_daily_sales_report(self, from_date, to_date):
        query = """
            SELECT DATE(BookingDateTime) as date, COUNT(*) as tickets, SUM(Fare) as revenue
            FROM Tickets
            WHERE DATE(BookingDateTime) BETWEEN %s AND %s
            GROUP BY DATE(BookingDateTime)
            ORDER BY date
        """
        results = self.execute_query(query, (from_date, to_date))
        
        self.report_text.insert(tk.END, f"Daily Ticket Sales Report ({from_date} to {to_date})\n")
        self.report_text.insert(tk.END, "="*50 + "\n\n")
        
        total_tickets = 0
        total_revenue = 0
        
        for row in results:
            self.report_text.insert(tk.END, f"{row['date']}: {row['tickets']} tickets, Revenue: ₹{row['revenue']:,.2f}\n")
            total_tickets += row['tickets']
            total_revenue += row['revenue']
        
        self.report_text.insert(tk.END, "\n" + "="*50 + "\n")
        self.report_text.insert(tk.END, f"Total Tickets: {total_tickets}\n")
        self.report_text.insert(tk.END, f"Total Revenue: ₹{total_revenue:,.2f}\n")
        
        # Create chart
        dates = [row['date'].strftime('%m-%d') for row in results]
        tickets = [row['tickets'] for row in results]
        
        fig = plt.Figure(figsize=(8, 4), dpi=100)
        ax = fig.add_subplot(111)
        ax.bar(dates, tickets)
        ax.set_title('Daily Ticket Sales')
        ax.set_xlabel('Date')
        ax.set_ylabel('Number of Tickets')
        
        canvas = FigureCanvasTkAgg(fig, master=self.chart_frame)
        canvas.draw()
        canvas.get_tk_widget().pack(fill=tk.BOTH, expand=True)

    def generate_revenue_by_train_report(self, from_date, to_date):
        query = """
            SELECT t.TrainName, COUNT(*) as tickets, SUM(p.Amount) as revenue
            FROM Payments p
            JOIN Tickets t ON p.TicketID = t.TicketID
            WHERE DATE(p.TransactionDateTime) BETWEEN %s AND %s
            AND p.PaymentStatus = 'Completed'
            GROUP BY t.TrainName
            ORDER BY revenue DESC
        """
        results = self.execute_query(query, (from_date, to_date))
        
        self.report_text.insert(tk.END, f"Revenue by Train Report ({from_date} to {to_date})\n")
        self.report_text.insert(tk.END, "="*50 + "\n\n")
        
        for row in results:
            self.report_text.insert(tk.END, f"{row['TrainName']}: {row['tickets']} tickets, Revenue: ₹{row['revenue']:,.2f}\n")
        
        # Create chart
        trains = [row['TrainName'] for row in results]
        revenue = [row['revenue'] for row in results]
        
        fig = plt.Figure(figsize=(8, 4), dpi=100)
        ax = fig.add_subplot(111)
        ax.bar(trains, revenue)
        ax.set_title('Revenue by Train')
        ax.set_xlabel('Train')
        ax.set_ylabel('Revenue (₹)')
        plt.xticks(rotation=45, ha='right')
        
        canvas = FigureCanvasTkAgg(fig, master=self.chart_frame)
        canvas.draw()
        canvas.get_tk_widget().pack(fill=tk.BOTH, expand=True)

    def generate_revenue_by_class_report(self, from_date, to_date):
        query = """
            SELECT t.Class, COUNT(*) as tickets, SUM(p.Amount) as revenue
            FROM Payments p
            JOIN Tickets t ON p.TicketID = t.TicketID
            WHERE DATE(p.TransactionDateTime) BETWEEN %s AND %s
            AND p.PaymentStatus = 'Completed'
            GROUP BY t.Class
            ORDER BY revenue DESC
        """
        results = self.execute_query(query, (from_date, to_date))
        
        self.report_text.insert(tk.END, f"Revenue by Class Report ({from_date} to {to_date})\n")
        self.report_text.insert(tk.END, "="*50 + "\n\n")
        
        for row in results:
            self.report_text.insert(tk.END, f"{row['Class']}: {row['tickets']} tickets, Revenue: ₹{row['revenue']:,.2f}\n")
        
        # Create chart
        classes = [row['Class'] for row in results]
        revenue = [row['revenue'] for row in results]
        
        fig = plt.Figure(figsize=(8, 4), dpi=100)
        ax = fig.add_subplot(111)
        ax.pie(revenue, labels=classes, autopct='%1.1f%%')
        ax.set_title('Revenue by Class')
        
        canvas = FigureCanvasTkAgg(fig, master=self.chart_frame)
        canvas.draw()
        canvas.get_tk_widget().pack(fill=tk.BOTH, expand=True)

    def generate_cancellation_report(self, from_date, to_date):
        query = """
            SELECT DATE(c.CancellationDateTime) as date, COUNT(*) as cancellations, 
                SUM(c.RefundAmount) as refund_amount
            FROM Cancellations c
            WHERE DATE(c.CancellationDateTime) BETWEEN %s AND %s
            GROUP BY DATE(c.CancellationDateTime)
            ORDER BY date
        """
        results = self.execute_query(query, (from_date, to_date))
        
        self.report_text.insert(tk.END, f"Cancellation Analysis Report ({from_date} to {to_date})\n")
        self.report_text.insert(tk.END, "="*50 + "\n\n")
        
        total_cancellations = 0
        total_refund = 0
        
        for row in results:
            self.report_text.insert(tk.END, f"{row['date']}: {row['cancellations']} cancellations, Refund: ₹{row['refund_amount']:,.2f}\n")
            total_cancellations += row['cancellations']
            total_refund += row['refund_amount']
        
        self.report_text.insert(tk.END, "\n" + "="*50 + "\n")
        self.report_text.insert(tk.END, f"Total Cancellations: {total_cancellations}\n")
        self.report_text.insert(tk.END, f"Total Refund Amount: ₹{total_refund:,.2f}\n")
        
        # Create chart
        dates = [row['date'].strftime('%m-%d') for row in results]
        cancellations = [row['cancellations'] for row in results]
        
        fig = plt.Figure(figsize=(8, 4), dpi=100)
        ax = fig.add_subplot(111)
        ax.plot(dates, cancellations, marker='o')
        ax.set_title('Daily Cancellations')
        ax.set_xlabel('Date')
        ax.set_ylabel('Number of Cancellations')
        
        canvas = FigureCanvasTkAgg(fig, master=self.chart_frame)
        canvas.draw()
        canvas.get_tk_widget().pack(fill=tk.BOTH, expand=True)

    def generate_demographics_report(self):
        # Age distribution
        age_query = """
            SELECT 
                CASE
                    WHEN Age < 18 THEN 'Under 18'
                    WHEN Age BETWEEN 18 AND 30 THEN '18-30'
                    WHEN Age BETWEEN 31 AND 45 THEN '31-45'
                    WHEN Age BETWEEN 46 AND 60 THEN '46-60'
                    ELSE 'Over 60'
                END as age_group,
                COUNT(*) as count
            FROM Passengers
            GROUP BY age_group
            ORDER BY age_group
        """
        age_results = self.execute_query(age_query)
        
        # Gender distribution
        gender_query = """
            SELECT Gender, COUNT(*) as count
            FROM Passengers
            GROUP BY Gender
        """
        gender_results = self.execute_query(gender_query)
        
        self.report_text.insert(tk.END, "Passenger Demographics Report\n")
        self.report_text.insert(tk.END, "="*50 + "\n\n")
        
        self.report_text.insert(tk.END, "Age Distribution:\n")
        for row in age_results:
            self.report_text.insert(tk.END, f"{row['age_group']}: {row['count']} passengers\n")
        
        self.report_text.insert(tk.END, "\nGender Distribution:\n")
        for row in gender_results:
            self.report_text.insert(tk.END, f"{row['Gender']}: {row['count']} passengers\n")
        
        # Create age distribution chart
        fig1 = plt.Figure(figsize=(8, 4), dpi=100)
        ax1 = fig1.add_subplot(121)
        age_groups = [row['age_group'] for row in age_results]
        age_counts = [row['count'] for row in age_results]
        ax1.bar(age_groups, age_counts)
        ax1.set_title('Age Distribution')
        ax1.set_xlabel('Age Group')
        ax1.set_ylabel('Number of Passengers')
        
        # Create gender distribution chart
        ax2 = fig1.add_subplot(122)
        genders = [row['Gender'] for row in gender_results]
        gender_counts = [row['count'] for row in gender_results]
        ax2.pie(gender_counts, labels=genders, autopct='%1.1f%%')
        ax2.set_title('Gender Distribution')
        
        canvas = FigureCanvasTkAgg(fig1, master=self.chart_frame)
        canvas.draw()
        canvas.get_tk_widget().pack(fill=tk.BOTH, expand=True)

    def __del__(self):
        if self.connection and self.connection.is_connected():
            self.connection.close()


root = tk.Tk()
app = RailwayDashboard(root)
root.mainloop()